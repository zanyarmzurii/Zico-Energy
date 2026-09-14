# ZICO Energy v7 — ALL-IN Production Package

This package contains the ZICO customer website, Admin Center and a production-ready Vercel/Supabase API layer.

## What is already filled
- Premium responsive UI, 5 languages, RTL/LTR
- IQD/SEK region-aware order validation
- Commerce/order API
- Global Demand Engine API
- Distributor applications + admin status workflow
- Reviews + admin moderation
- ZICO Club event/points API foundation
- Admin summary + order/review/distributor controls
- PWA, SEO, security headers and WebP assets
- CORS allow-list support
- Database constraints, indexes and RLS enabled
- `/api/health` performs a real Supabase connectivity check

## Only account-owned values remain
I cannot invent or embed your private production credentials or verified distributor phone numbers. Before deployment, create your own Supabase project and set:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ZICO_ADMIN_KEY` (use a long random secret)
- `ZICO_ALLOWED_ORIGINS` (your real website origin)

### Supabase
1. Create a Supabase project.
2. Open SQL Editor.
3. Run `supabase-schema.sql`.
4. Copy the project URL and service-role key into Vercel Environment Variables.

### Vercel
1. Import this repository/package into a Vercel project.
2. Add the four environment variables above for Production (and Preview if needed).
3. Deploy.
4. Open `/api/health`. It should return `database: connected`.
5. Open `/admin.html` and sign in using `ZICO_ADMIN_KEY`.

### Security
Never put `SUPABASE_SERVICE_ROLE_KEY` in `index.html`, client-side JavaScript, GitHub, or public documentation. It is server-only.

### Verified distributors
Add only real, verified business numbers to the front-end configuration. Sweden remains intentionally unconfigured until you provide the verified number.
