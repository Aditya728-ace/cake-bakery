import uuid
from datetime import datetime, timezone
from decimal import Decimal
from sqlalchemy import (JSON, Boolean, DateTime, ForeignKey, Index, Integer,
                        Numeric, String, Text, Uuid)
from sqlalchemy.orm import Mapped, mapped_column, relationship
from .database import Base


def now():
    return datetime.now(timezone.utc)


class User(Base):
    __tablename__ = "users"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    email: Mapped[str] = mapped_column(String(255), unique=True, index=True)
    password_hash: Mapped[str] = mapped_column(String(255))
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    profile: Mapped["BakeryProfile"] = relationship(back_populates="user", uselist=False,
                                                    cascade="all, delete-orphan")


class BakeryProfile(Base):
    __tablename__ = "bakery_profiles"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    user_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("users.id", ondelete="CASCADE"), unique=True)
    name: Mapped[str] = mapped_column(String(120))
    tagline: Mapped[str | None] = mapped_column(String(200))
    email: Mapped[str | None] = mapped_column(String(255))
    phone: Mapped[str | None] = mapped_column(String(30))
    whatsapp_number: Mapped[str | None] = mapped_column(String(20))
    address: Mapped[str | None] = mapped_column(Text)
    logo_url: Mapped[str | None] = mapped_column(Text)
    logo_public_id: Mapped[str | None] = mapped_column(String(255))
    social_links: Mapped[dict] = mapped_column(JSON, default=dict)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, onupdate=now)
    user: Mapped[User] = relationship(back_populates="profile")
    cakes: Mapped[list["Cake"]] = relationship(back_populates="profile", cascade="all, delete-orphan")


class Cake(Base):
    __tablename__ = "cakes"
    __table_args__ = (Index("ix_cakes_published", "is_published", "created_at"),)
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    profile_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("bakery_profiles.id", ondelete="CASCADE"))
    slug: Mapped[str] = mapped_column(String(160), unique=True, index=True)
    title: Mapped[str] = mapped_column(String(140))
    description: Mapped[str] = mapped_column(Text, default="")
    ingredients: Mapped[list] = mapped_column(JSON, default=list)
    price: Mapped[Decimal | None] = mapped_column(Numeric(10, 2))
    currency: Mapped[str] = mapped_column(String(3), default="INR")
    is_available: Mapped[bool] = mapped_column(Boolean, default=True)
    is_published: Mapped[bool] = mapped_column(Boolean, default=False)
    is_featured: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, onupdate=now)
    profile: Mapped[BakeryProfile] = relationship(back_populates="cakes")
    images: Mapped[list["CakeImage"]] = relationship(back_populates="cake", cascade="all, delete-orphan",
                                                     order_by="CakeImage.position", lazy="selectin")

    @property
    def cover_url(self):
        if not self.images:
            return None
        cover = next((i for i in self.images if i.is_cover), self.images[0])
        return cover.url


class CakeImage(Base):
    __tablename__ = "cake_images"
    id: Mapped[uuid.UUID] = mapped_column(Uuid, primary_key=True, default=uuid.uuid4)
    cake_id: Mapped[uuid.UUID] = mapped_column(ForeignKey("cakes.id", ondelete="CASCADE"), index=True)
    url: Mapped[str] = mapped_column(Text)
    public_id: Mapped[str] = mapped_column(String(255))
    width: Mapped[int | None] = mapped_column(Integer)
    height: Mapped[int | None] = mapped_column(Integer)
    position: Mapped[int] = mapped_column(Integer, default=0)
    is_cover: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now)
    cake: Mapped[Cake] = relationship(back_populates="images")


class SiteContent(Base):
    __tablename__ = "site_content"
    key: Mapped[str] = mapped_column(String(60), primary_key=True)
    value: Mapped[str] = mapped_column(Text, default="")
    updated_at: Mapped[datetime] = mapped_column(DateTime(timezone=True), default=now, onupdate=now)
