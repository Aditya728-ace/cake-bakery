"""Image storage (Cloudinary). Files never touch the database; only URL + public_id are stored."""
import io
import cloudinary
import cloudinary.uploader
from fastapi import HTTPException, UploadFile
from PIL import Image, UnidentifiedImageError
from .config import get_settings

ALLOWED = {"JPEG", "PNG", "WEBP"}


def _configure():
    s = get_settings()
    cloudinary.config(cloud_name=s.CLOUDINARY_CLOUD_NAME, api_key=s.CLOUDINARY_API_KEY,
                      api_secret=s.CLOUDINARY_API_SECRET, secure=True)


async def read_validated(file: UploadFile) -> tuple[bytes, int, int]:
    s = get_settings()
    limit = s.MAX_UPLOAD_MB * 1024 * 1024
    data = await file.read(limit + 1)
    if len(data) > limit:
        raise HTTPException(413, f"Image exceeds {s.MAX_UPLOAD_MB} MB")
    try:
        img = Image.open(io.BytesIO(data))
        fmt = img.format
        img.verify()
    except (UnidentifiedImageError, OSError):
        raise HTTPException(422, "File is not a valid image")
    if fmt not in ALLOWED:
        raise HTTPException(422, "Only JPEG, PNG or WEBP images are allowed")
    w, h = Image.open(io.BytesIO(data)).size
    return data, w, h


def upload_image(data: bytes, folder: str) -> dict:
    _configure()
    try:
        res = cloudinary.uploader.upload(data, folder=f"bakery/{folder}", resource_type="image")
    except Exception:
        raise HTTPException(502, "Image storage is unavailable, please try again")
    return {"url": res["secure_url"], "public_id": res["public_id"]}


def delete_image(public_id: str) -> None:
    _configure()
    try:
        cloudinary.uploader.destroy(public_id)
    except Exception:
        pass  # best effort; DB row is removed regardless
