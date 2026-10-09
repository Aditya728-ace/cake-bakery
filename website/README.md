# Bakery Website (React + Vite)

## Run locally
```bash
npm install
VITE_DEMO=true npm run dev     # preview with sample cakes, no backend needed
npm run dev                    # real data: backend must run on :8000 (Vite proxies /api)
```

## Deploy (Vercel or Netlify)
1. Import the repo, set **root directory** to `website`. Build: `npm run build`, output: `dist`.
2. Add env var `VITE_API_URL` = your deployed backend URL (no trailing slash).
3. Add the website's final URL to the backend's `CORS_ORIGINS` and redeploy the backend.
SPA routing is already handled (`vercel.json` / `public/_redirects`).

## Editable from the Flutter app (no code)
Bakery name, tagline, logo, phone/email/WhatsApp/address, social links, hero text and photo,
story text, announcement bar, footer note, and every cake.
