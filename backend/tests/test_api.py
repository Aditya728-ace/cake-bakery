import io
import os
os.environ["DATABASE_URL"] = "sqlite:///./test.db"
os.environ["ADMIN_INVITE_CODE"] = ""
import pytest
from fastapi.testclient import TestClient
from PIL import Image
from app import ratelimit, storage
from app.database import Base, engine
from app.main import app


@pytest.fixture()
def client(monkeypatch):
    Base.metadata.drop_all(engine)
    Base.metadata.create_all(engine)
    ratelimit.reset()
    n = {"i": 0}

    def fake_upload(data, folder):
        n["i"] += 1
        return {"url": f"https://img.test/{n['i']}.jpg", "public_id": f"p{n['i']}"}
    monkeypatch.setattr(storage, "upload_image", fake_upload)
    monkeypatch.setattr(storage, "delete_image", lambda pid: None)
    return TestClient(app)


def png():
    b = io.BytesIO()
    Image.new("RGB", (20, 20), "brown").save(b, "PNG")
    return b.getvalue()


def auth(client):
    r = client.post("/api/auth/register", json={"email": "owner@x.com", "password": "supersecret1",
                                                "bakery_name": "Test Bakery"})
    assert r.status_code == 201
    return {"Authorization": f"Bearer {r.json()['access_token']}"}


def test_admin_requires_auth(client):
    assert client.get("/api/admin/cakes").status_code == 401
    assert client.post("/api/admin/cakes", json={"title": "x"}).status_code == 401


def test_registration_closed_after_first_owner(client):
    auth(client)
    r = client.post("/api/auth/register", json={"email": "b@x.com", "password": "supersecret1",
                                                "bakery_name": "Other"})
    assert r.status_code == 403


def test_login_errors(client):
    auth(client)
    assert client.post("/api/auth/login", json={"email": "owner@x.com", "password": "wrong"}).status_code == 401
    assert client.post("/api/auth/login", json={"email": "owner@x.com", "password": "supersecret1"}).status_code == 200


def test_full_cake_flow_syncs_to_public_api(client):
    h = auth(client)
    r = client.post("/api/admin/cakes", headers=h, json={
        "title": "Royal Truffle", "description": "Rich.", "ingredients": [" Cocoa ", "", "Cream"],
        "price": "1499.00"})
    assert r.status_code == 201
    cake = r.json()
    assert cake["ingredients"] == ["Cocoa", "Cream"] and cake["is_published"] is False

    # draft is invisible on the website
    assert client.get("/api/public/cakes").json() == []
    # cannot publish without photos
    assert client.post(f"/api/admin/cakes/{cake['id']}/publish", headers=h).status_code == 422

    r = client.post(f"/api/admin/cakes/{cake['id']}/images", headers=h,
                    files=[("files", ("a.png", png(), "image/png"))])
    assert r.status_code == 201 and r.json()["images"][0]["is_cover"] is True

    assert client.post(f"/api/admin/cakes/{cake['id']}/publish", headers=h).status_code == 200
    pub = client.get("/api/public/cakes").json()
    assert len(pub) == 1 and pub[0]["cover_url"].startswith("https://img.test/")
    assert "is_published" not in pub[0]
    assert client.get(f"/api/public/cakes/{cake['slug']}").status_code == 200

    client.patch(f"/api/admin/cakes/{cake['id']}", headers=h, json={"title": "Royal Truffle XL"})
    assert client.get("/api/public/cakes").json()[0]["title"] == "Royal Truffle XL"

    client.post(f"/api/admin/cakes/{cake['id']}/unpublish", headers=h)
    assert client.get("/api/public/cakes").json() == []
    assert client.get(f"/api/public/cakes/{cake['slug']}").status_code == 404

    assert client.delete(f"/api/admin/cakes/{cake['id']}", headers=h).status_code == 204


def test_rejects_non_images_and_bad_input(client):
    h = auth(client)
    cid = client.post("/api/admin/cakes", headers=h, json={"title": "Cake"}).json()["id"]
    r = client.post(f"/api/admin/cakes/{cid}/images", headers=h,
                    files=[("files", ("a.png", b"not an image", "image/png"))])
    assert r.status_code == 422
    assert client.post("/api/admin/cakes", headers=h, json={"title": "Cake", "price": -5}).status_code == 422
    assert client.put("/api/admin/profile", headers=h, json={"whatsapp_number": "abc"}).status_code == 422


def test_profile_and_content(client):
    h = auth(client)
    r = client.put("/api/admin/profile", headers=h, json={
        "phone": "+91 98765 43210", "whatsapp_number": "+91 98765-43210",
        "social_links": {"instagram": "https://instagram.com/bakery"}})
    assert r.status_code == 200 and r.json()["whatsapp_number"] == "919876543210"
    assert client.put("/api/admin/profile", headers=h,
                      json={"social_links": {"myspace": "https://x.com"}}).status_code == 422
    client.put("/api/admin/content", headers=h, json={"values": {"hero_title": "Baked with love"}})
    assert client.get("/api/public/content").json()["hero_title"] == "Baked with love"
    assert client.put("/api/admin/content", headers=h, json={"values": {"evil": "x"}}).status_code == 422
    assert client.get("/api/public/bakery").json()["name"] == "Test Bakery"


def test_login_is_rate_limited(client):
    auth(client)
    for _ in range(10):
        assert client.post("/api/auth/login", json={"email": "owner@x.com", "password": "bad"}).status_code == 401
    r = client.post("/api/auth/login", json={"email": "owner@x.com", "password": "supersecret1"})
    assert r.status_code == 429
