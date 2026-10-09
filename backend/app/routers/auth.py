import secrets
import uuid
from fastapi import APIRouter, Depends, HTTPException, Request, status
from sqlalchemy import func, select
from sqlalchemy.orm import Session
from ..config import get_settings
from ..database import get_db
from ..deps import current_user
from ..models import BakeryProfile, User
from .. import ratelimit
from ..schemas import LoginIn, RefreshIn, RegisterIn, TokenOut
from ..security import create_tokens, decode_token, hash_password, verify_password

router = APIRouter(prefix="/api/auth", tags=["auth"])
_DUMMY = hash_password("not-a-real-password")  # equalises timing for unknown emails


@router.post("/register", response_model=TokenOut, status_code=201)
def register(body: RegisterIn, request: Request, db: Session = Depends(get_db)):
    ratelimit.guard(request)
    s = get_settings()
    has_users = db.scalar(select(func.count()).select_from(User)) > 0
    if has_users:  # the site has one owner; extra accounts need the invite code
        ok = bool(s.ADMIN_INVITE_CODE) and body.invite_code and \
            secrets.compare_digest(body.invite_code, s.ADMIN_INVITE_CODE)
        if not ok:
            ratelimit.record_failure(request)
            raise HTTPException(403, "Registration is closed")
    elif s.ADMIN_INVITE_CODE and not (body.invite_code and
            secrets.compare_digest(body.invite_code, s.ADMIN_INVITE_CODE)):
        ratelimit.record_failure(request)
        raise HTTPException(403, "Invalid invite code")
    email = body.email.lower()
    if db.scalar(select(User).where(User.email == email)):
        raise HTTPException(409, "Email already registered")
    user = User(email=email, password_hash=hash_password(body.password))
    user.profile = BakeryProfile(name=body.bakery_name, email=email, social_links={})
    db.add(user)
    db.commit()
    return create_tokens(str(user.id))


@router.post("/login", response_model=TokenOut)
def login(body: LoginIn, request: Request, db: Session = Depends(get_db)):
    ratelimit.guard(request)
    user = db.scalar(select(User).where(User.email == body.email.lower()))
    ok = verify_password(body.password, user.password_hash if user else _DUMMY)
    if not user or not ok:
        ratelimit.record_failure(request)
        raise HTTPException(status.HTTP_401_UNAUTHORIZED, "Invalid email or password")
    ratelimit.reset(request)
    return create_tokens(str(user.id))


@router.post("/refresh", response_model=TokenOut)
def refresh(body: RefreshIn, db: Session = Depends(get_db)):
    sub = decode_token(body.refresh_token, "refresh")
    if not sub or not db.get(User, uuid.UUID(sub)):
        raise HTTPException(401, "Invalid refresh token")
    return create_tokens(sub)


@router.get("/me")
def me(user: User = Depends(current_user)):
    return {"id": str(user.id), "email": user.email}
