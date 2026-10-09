# Cake Bakery Platform

```
cake-bakery/
├── backend/   FastAPI + SQLAlchemy, 7 tests passing
├── website/   React + Vite
├── admin_app/ Flutter (see its README)
├── docs/DEPLOYMENT.md   step-by-step launch guide
└── render.yaml          backend blueprint for Render
```

## Backend quick start
```bash
cd backend
python -m venv .venv && source .venv/bin/activate
pip install -r requirements.txt
cp .env.example .env        # fill in DATABASE_URL (Neon), JWT_SECRET, Cloudinary keys
python -m app.init_db       # creates tables in Neon (or paste schema.sql in Neon's SQL editor)
uvicorn app.main:app --reload
# open http://localhost:8000/docs   |   run tests: pytest
```

## Deploy backend (Render, free tier works)
1. Push repo to GitHub. New **Web Service** → root dir `backend`.
2. Build: `pip install -r requirements.txt`
3. Start: `gunicorn app.main:app -k uvicorn.workers.UvicornWorker -w 2 -b 0.0.0.0:$PORT`
4. Env vars: everything in `.env.example`, with `ENVIRONMENT=production` and `CORS_ORIGINS` = your website URL.
5. Run `python -m app.init_db` once from the Render shell.

## Neon
Create a project → copy the **pooled** connection string (must include `sslmode=require`) into `DATABASE_URL`.
Credentials live only in backend env vars.
