"""Protected endpoints used by the Flutter admin app. Every route requires a valid access token
and is scoped to the authenticated owner's bakery."""
import re
import uuid
from fastapi import APIRouter, Depends, File, HTTPException, UploadFile
from sqlalchemy import select
from sqlalchemy.orm import Session
from .. import storage
from ..config import get_settings
from ..database import get_db
from ..deps import current_profile, current_user
from ..models import BakeryProfile, Cake, CakeImage, SiteContent, User
from ..schemas import (CONTENT_KEYS, AdminCakeOut, CakeCreate, CakeUpdate, ContentUpdate,
                       ProfileOut, ProfileUpdate)

router = APIRouter(prefix="/api/admin", tags=["admin"], dependencies=[Depends(current_user)])


# ---------- profile
@router.get("/profile", response_model=ProfileOut)
def get_profile(p: BakeryProfile = Depends(current_profile)):
    return p


@router.put("/profile", response_model=ProfileOut)
def update_profile(body: ProfileUpdate, p: BakeryProfile = Depends(current_profile),
                   db: Session = Depends(get_db)):
    for k, v in body.model_dump(exclude_unset=True).items():
        setattr(p, k, v)
    db.add(p)
    db.commit()
    return p


@router.post("/profile/logo", response_model=ProfileOut)
async def upload_logo(file: UploadFile = File(...), p: BakeryProfile = Depends(current_profile),
                      db: Session = Depends(get_db)):
    data, _, _ = await storage.read_validated(file)
    res = storage.upload_image(data, "logo")
    old = p.logo_public_id
    p.logo_url, p.logo_public_id = res["url"], res["public_id"]
    db.commit()
    if old:
        storage.delete_image(old)
    return p


# ---------- cakes
def _slug(db: Session, title: str) -> str:
    base = re.sub(r"[^a-z0-9]+", "-", title.lower()).strip("-")[:120] or "cake"
    slug = base
    while db.scalar(select(Cake.id).where(Cake.slug == slug)):
        slug = f"{base}-{uuid.uuid4().hex[:6]}"
    return slug


def _own_cake(db: Session, cake_id: uuid.UUID, p: BakeryProfile) -> Cake:
    cake = db.scalar(select(Cake).where(Cake.id == cake_id, Cake.profile_id == p.id))
    if not cake:
        raise HTTPException(404, "Cake not found")
    return cake


@router.get("/cakes", response_model=list[AdminCakeOut])
def list_cakes(p: BakeryProfile = Depends(current_profile), db: Session = Depends(get_db)):
    return list(db.scalars(select(Cake).where(Cake.profile_id == p.id).order_by(Cake.created_at.desc())))


@router.post("/cakes", response_model=AdminCakeOut, status_code=201)
def create_cake(body: CakeCreate, p: BakeryProfile = Depends(current_profile),
                db: Session = Depends(get_db)):
    cake = Cake(profile_id=p.id, slug=_slug(db, body.title), is_published=False, **body.model_dump())
    db.add(cake)
    db.commit()
    return cake


@router.get("/cakes/{cake_id}", response_model=AdminCakeOut)
def get_cake(cake_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
             db: Session = Depends(get_db)):
    return _own_cake(db, cake_id, p)


@router.patch("/cakes/{cake_id}", response_model=AdminCakeOut)
def update_cake(cake_id: uuid.UUID, body: CakeUpdate, p: BakeryProfile = Depends(current_profile),
                db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    for k, v in body.model_dump(exclude_unset=True).items():
        if v is None and k in {"title", "description", "ingredients", "currency",
                               "is_available", "is_featured"}:
            continue  # these cannot be nulled; price can
        setattr(cake, k, v)
    db.commit()
    return cake


@router.post("/cakes/{cake_id}/publish", response_model=AdminCakeOut)
def publish(cake_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
            db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    if not cake.images:
        raise HTTPException(422, "Add at least one photo before publishing")
    cake.is_published = True
    db.commit()
    return cake


@router.post("/cakes/{cake_id}/unpublish", response_model=AdminCakeOut)
def unpublish(cake_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
              db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    cake.is_published = False
    db.commit()
    return cake


@router.delete("/cakes/{cake_id}", status_code=204)
def delete_cake(cake_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
                db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    ids = [i.public_id for i in cake.images]
    db.delete(cake)
    db.commit()
    for pid in ids:
        storage.delete_image(pid)


# ---------- cake images
@router.post("/cakes/{cake_id}/images", response_model=AdminCakeOut, status_code=201)
async def add_images(cake_id: uuid.UUID, files: list[UploadFile] = File(...),
                     p: BakeryProfile = Depends(current_profile), db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    s = get_settings()
    if len(cake.images) + len(files) > s.MAX_IMAGES_PER_CAKE:
        raise HTTPException(422, f"A cake can have at most {s.MAX_IMAGES_PER_CAKE} photos")
    validated = [await storage.read_validated(f) for f in files]  # validate all before uploading any
    pos = max((i.position for i in cake.images), default=-1) + 1
    for data, w, h in validated:
        res = storage.upload_image(data, f"cakes/{cake.id}")
        db.add(CakeImage(cake_id=cake.id, url=res["url"], public_id=res["public_id"], width=w,
                         height=h, position=pos, is_cover=(not cake.images and pos == 0)))
        pos += 1
        db.flush()
        db.refresh(cake)
    db.commit()
    db.refresh(cake)
    return cake


@router.put("/cakes/{cake_id}/images/{image_id}/cover", response_model=AdminCakeOut)
def set_cover(cake_id: uuid.UUID, image_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
              db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    if image_id not in {i.id for i in cake.images}:
        raise HTTPException(404, "Image not found")
    for i in cake.images:
        i.is_cover = i.id == image_id
    db.commit()
    return cake


@router.delete("/cakes/{cake_id}/images/{image_id}", response_model=AdminCakeOut)
def delete_image(cake_id: uuid.UUID, image_id: uuid.UUID, p: BakeryProfile = Depends(current_profile),
                 db: Session = Depends(get_db)):
    cake = _own_cake(db, cake_id, p)
    img = next((i for i in cake.images if i.id == image_id), None)
    if not img:
        raise HTTPException(404, "Image not found")
    was_cover, pid = img.is_cover, img.public_id
    cake.images.remove(img)
    db.flush()
    if cake.images and was_cover:
        cake.images[0].is_cover = True
    if not cake.images:
        cake.is_published = False  # never leave a published cake without photos
    db.commit()
    storage.delete_image(pid)
    return cake


# ---------- website content (no-code editing)
@router.get("/content")
def get_content(db: Session = Depends(get_db)):
    rows = {r.key: r.value for r in db.scalars(select(SiteContent))}
    return {k: rows.get(k, "") for k in CONTENT_KEYS}


@router.put("/content")
def put_content(body: ContentUpdate, db: Session = Depends(get_db)):
    for k, v in body.values.items():
        row = db.get(SiteContent, k)
        if row:
            row.value = v
        else:
            db.add(SiteContent(key=k, value=v))
    db.commit()
    return get_content(db)


@router.post("/content/hero-image")
async def hero_image(file: UploadFile = File(...), db: Session = Depends(get_db)):
    data, _, _ = await storage.read_validated(file)
    res = storage.upload_image(data, "site")
    row = db.get(SiteContent, "hero_image_url")
    if row:
        row.value = res["url"]
    else:
        db.add(SiteContent(key="hero_image_url", value=res["url"]))
    db.commit()
    return {"hero_image_url": res["url"]}
