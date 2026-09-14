# ZICO Security Setup

## Required Vercel Environment Variables

Set these in Vercel Project Settings → Environment Variables:

- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`
- `ZICO_ADMIN_KEY`
- `ZICO_ALLOWED_ORIGINS`
- `ZICO_SWEDEN_WHATSAPP` (when the official Sweden number is confirmed)
- `ZICO_SWEDEN_SINGLE_PRICE`
- `ZICO_SWEDEN_BUNDLE_PRICE`
- `NEXT_PUBLIC_SITE_URL`
- `NEXT_PUBLIC_SUPABASE_URL`

Never put `SUPABASE_SERVICE_ROLE_KEY` or `ZICO_ADMIN_KEY` in frontend code or any variable beginning with `NEXT_PUBLIC_`.

## Rotate the exposed service-role key

The service-role JWT previously pasted into chat should be considered compromised. Revoke/rotate it in Supabase and put the new key only in Vercel's server environment.

## Admin key

Generate a long random value, for example with:

`openssl rand -base64 48`

Do not use a human password.

## API protections added

- Strict configured CORS origins; wildcard `*` is not used when origins are configured.
- Basic per-IP throttling for public write endpoints and admin requests.
- Request body size bound for string bodies.
- Server-side order price calculation.
- Browser-supplied `total` and `unitPrice` are ignored.
- Sweden orders are rejected until Sweden pricing is configured.
- Security response headers and `Vary: Origin` are added.
- User-provided strings are bounded and sanitized before storage.

For stronger production abuse protection, also enable Vercel WAF/Firewall rate limits and Supabase monitoring.
