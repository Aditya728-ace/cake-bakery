from datetime import datetime, timedelta, timezone
import bcrypt
import jwt
from .config import get_settings


def hash_password(pw: str) -> str:
    return bcrypt.hashpw(pw.encode()[:72], bcrypt.gensalt(12)).decode()


def verify_password(pw: str, hashed: str) -> bool:
    try:
        return bcrypt.checkpw(pw.encode()[:72], hashed.encode())
    except ValueError:
        return False


def _token(sub: str, kind: str, delta: timedelta) -> str:
    s = get_settings()
    exp = datetime.now(timezone.utc) + delta
    return jwt.encode({"sub": sub, "type": kind, "exp": exp}, s.JWT_SECRET, algorithm="HS256")


def create_tokens(user_id: str) -> dict:
    s = get_settings()
    return {
        "access_token": _token(user_id, "access", timedelta(minutes=s.ACCESS_TOKEN_MINUTES)),
        "refresh_token": _token(user_id, "refresh", timedelta(days=s.REFRESH_TOKEN_DAYS)),
        "token_type": "bearer",
    }


def decode_token(token: str, expected: str) -> str | None:
    try:
        data = jwt.decode(token, get_settings().JWT_SECRET, algorithms=["HS256"])
    except jwt.PyJWTError:
        return None
    return data["sub"] if data.get("type") == expected else None
