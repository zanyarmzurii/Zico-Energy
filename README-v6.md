# ZICO Energy v6.0

## Included
- Responsive premium UI with accessibility and reduced-motion support
- 5-language foundation with RTL/LTR
- Region-aware IQD / SEK order formatting
- API-first Demand Engine, distributor applications, reviews and ZICO Club events
- Local fallback when API is not configured
- PWA manifest + cache versioning
- WebP image optimization
- SEO/Open Graph metadata
- Vercel-compatible API scaffolding for Supabase

## Enable global backend
1. Create a Supabase project.
2. Run `supabase-schema.sql`.
3. Add Vercel environment variables `SUPABASE_URL` and `SUPABASE_SERVICE_ROLE_KEY`.
4. Deploy.
5. Test `/api/health`.

The frontend will automatically use `/api`; if the backend is unavailable it falls back to local device storage so the site remains usable.

## Important
The current distributor phone numbers already present in v5 are preserved. No unverified Sweden number was invented. Configure the real Sweden — Coming Soon before accepting Sweden — Coming Soon orders.
