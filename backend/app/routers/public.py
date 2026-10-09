"""Read-only endpoints used by the website. No auth; only published data is exposed."""
from fastapi import APIRouter, Depends, HTTPException, Query, Response
from sqlalchemy import select
from sqlalchemy.orm import Session
from ..database import get_db
from ..models import BakeryProfile, Cake, SiteContent
from ..schemas import CONTENT_KEYS, CakeOut, ProfileOut

router = APIRouter(prefix="/api/public", tags=["public"])
CACHE = "public, max-age=30, stale-while-revalidate=120"  # near-instant updates, light on the DB


@router.get("/bakery", response_model=ProfileOut)
def bakery(response: Response, db: Session = Depends(get_db)):
    p = db.scalar(select(BakeryProfile).order_by(BakeryProfile.updated_at))
    if not p:
        raise HTTPException(404, "Bakery not set up yet")
    response.headers["Cache-Control"] = CACHE
    return p


@router.get("/content")
def content(response: Response, db: Session = Depends(get_db)):
    rows = {r.key: r.value for r in db.scalars(select(SiteContent))}
    response.headers["Cache-Control"] = CACHE
    return {k: rows.get(k, "") for k in CONTENT_KEYS}


@router.get("/cakes", response_model=list[CakeOut])
def list_cakes(response: Response, featured: bool = False,
               limit: int = Query(60, ge=1, le=100), offset: int = Query(0, ge=0),
               db: Session = Depends(get_db)):
    q = select(Cake).where(Cake.is_published.is_(True))
    if featured:
        q = q.where(Cake.is_featured.is_(True))
    q = q.order_by(Cake.created_at.desc()).limit(limit).offset(offset)
    response.headers["Cache-Control"] = CACHE
    return list(db.scalars(q))


@router.get("/cakes/{slug}", response_model=CakeOut)
def cake_detail(slug: str, response: Response, db: Session = Depends(get_db)):
    cake = db.scalar(select(Cake).where(Cake.slug == slug, Cake.is_published.is_(True)))
    if not cake:
        raise HTTPException(404, "Cake not found")
    response.headers["Cache-Control"] = CACHE
    return cake
