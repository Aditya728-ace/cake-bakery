import logging
from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import JSONResponse
from .config import get_settings
from .database import Base, engine
from .routers import admin, auth, public

log = logging.getLogger("bakery")
s = get_settings()
prod = s.ENVIRONMENT == "production"

app = FastAPI(title="Bakery API", version="1.0.0",
              docs_url=None if prod else "/docs", redoc_url=None, openapi_url=None if prod else "/openapi.json")

app.add_middleware(
    CORSMiddleware,
    allow_origins=s.cors_list,  # website origins only; the Flutter app is not a browser so it needs no CORS
    allow_methods=["GET", "POST", "PUT", "PATCH", "DELETE"],
    allow_headers=["Authorization", "Content-Type"],
)


@app.middleware("http")
async def security_headers(request: Request, call_next):
    resp = await call_next(request)
    resp.headers["X-Content-Type-Options"] = "nosniff"
    resp.headers["Referrer-Policy"] = "no-referrer"
    if not request.url.path.startswith("/api/public"):
        resp.headers["Cache-Control"] = "no-store"
    return resp


@app.exception_handler(Exception)
async def unhandled(request: Request, exc: Exception):
    log.exception("Unhandled error on %s", request.url.path)
    return JSONResponse({"detail": "Something went wrong. Please try again."}, status_code=500)


app.include_router(auth.router)
app.include_router(public.router)
app.include_router(admin.router)


@app.get("/health")
def health():
    return {"status": "ok"}


if not prod:  # convenience for local dev; in production run `python -m app.init_db`
    Base.metadata.create_all(engine)
