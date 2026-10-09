import re
import uuid
from decimal import Decimal
from pydantic import BaseModel, ConfigDict, EmailStr, Field, HttpUrl, field_validator


class ORM(BaseModel):
    model_config = ConfigDict(from_attributes=True)


# ---- auth
class RegisterIn(BaseModel):
    email: EmailStr
    password: str = Field(min_length=10, max_length=72)
    bakery_name: str = Field(min_length=2, max_length=120)
    invite_code: str | None = None


class LoginIn(BaseModel):
    email: EmailStr
    password: str = Field(max_length=72)


class RefreshIn(BaseModel):
    refresh_token: str


class TokenOut(BaseModel):
    access_token: str
    refresh_token: str
    token_type: str = "bearer"


# ---- profile
SOCIAL_KEYS = {"instagram", "facebook", "youtube", "pinterest", "tiktok", "x"}


class ProfileUpdate(BaseModel):
    name: str | None = Field(None, min_length=2, max_length=120)
    tagline: str | None = Field(None, max_length=200)
    email: EmailStr | None = None
    phone: str | None = Field(None, max_length=30)
    whatsapp_number: str | None = Field(None, max_length=20)
    address: str | None = Field(None, max_length=500)
    social_links: dict[str, HttpUrl] | None = None

    @field_validator("whatsapp_number")
    @classmethod
    def digits_only(cls, v):
        if v is None or v == "":
            return v
        v = re.sub(r"[\s+\-()]", "", v)
        if not v.isdigit() or not 8 <= len(v) <= 15:
            raise ValueError("WhatsApp number must be digits with country code, e.g. 919876543210")
        return v

    @field_validator("social_links")
    @classmethod
    def known_keys(cls, v):
        if v is None:
            return v
        bad = set(v) - SOCIAL_KEYS
        if bad:
            raise ValueError(f"Unsupported social keys: {sorted(bad)}")
        return {k: str(u) for k, u in v.items()}


class ProfileOut(ORM):
    id: uuid.UUID
    name: str
    tagline: str | None
    email: str | None
    phone: str | None
    whatsapp_number: str | None
    address: str | None
    logo_url: str | None
    social_links: dict


# ---- cakes
def _clean(v):
    if v is None:
        return v
    out = [i.strip() for i in v if i and i.strip()]
    if any(len(i) > 80 for i in out):
        raise ValueError("Each ingredient must be 80 characters or fewer")
    return out


class CakeCreate(BaseModel):
    title: str = Field(min_length=2, max_length=140)
    description: str = Field("", max_length=4000)
    ingredients: list[str] = Field(default_factory=list, max_length=40)
    price: Decimal | None = Field(None, ge=0, le=1_000_000, decimal_places=2)
    currency: str = Field("INR", pattern=r"^[A-Z]{3}$")
    is_available: bool = True
    is_featured: bool = False
    _c = field_validator("ingredients")(classmethod(lambda cls, v: _clean(v)))


class CakeUpdate(BaseModel):
    title: str | None = Field(None, min_length=2, max_length=140)
    description: str | None = Field(None, max_length=4000)
    ingredients: list[str] | None = Field(None, max_length=40)
    price: Decimal | None = Field(None, ge=0, le=1_000_000, decimal_places=2)
    currency: str | None = Field(None, pattern=r"^[A-Z]{3}$")
    is_available: bool | None = None
    is_featured: bool | None = None
    _c = field_validator("ingredients")(classmethod(lambda cls, v: _clean(v)))


class ImageOut(ORM):
    id: uuid.UUID
    url: str
    width: int | None
    height: int | None
    position: int
    is_cover: bool


class CakeOut(ORM):
    id: uuid.UUID
    slug: str
    title: str
    description: str
    ingredients: list[str]
    price: Decimal | None
    currency: str
    is_available: bool
    is_featured: bool
    images: list[ImageOut]
    cover_url: str | None = None


class AdminCakeOut(CakeOut):
    is_published: bool


# ---- site content (editable website copy)
CONTENT_KEYS = ["hero_title", "hero_subtitle", "hero_cta_label", "about_title", "about_body",
                "announcement", "footer_note", "hero_image_url"]


class ContentUpdate(BaseModel):
    values: dict[str, str]

    @field_validator("values")
    @classmethod
    def valid(cls, v):
        bad = set(v) - set(CONTENT_KEYS)
        if bad:
            raise ValueError(f"Unknown content keys: {sorted(bad)}")
        if any(len(x) > 5000 for x in v.values()):
            raise ValueError("Content value too long")
        return v
