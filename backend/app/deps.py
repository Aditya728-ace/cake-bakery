import uuid
from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer
from sqlalchemy.orm import Session
from .database import get_db
from .models import BakeryProfile, User
from .security import decode_token

bearer = HTTPBearer(auto_error=False)


def current_user(creds: HTTPAuthorizationCredentials | None = Depends(bearer),
                 db: Session = Depends(get_db)) -> User:
    err = HTTPException(status.HTTP_401_UNAUTHORIZED, "Not authenticated",
                        headers={"WWW-Authenticate": "Bearer"})
    if not creds:
        raise err
    sub = decode_token(creds.credentials, "access")
    if not sub:
        raise err
    user = db.get(User, uuid.UUID(sub))
    if not user:
        raise err
    return user


def current_profile(user: User = Depends(current_user)) -> BakeryProfile:
    return user.profile
