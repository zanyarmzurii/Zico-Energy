# ZICO Rewards v8

This build adds a production-oriented loyalty layer:

- Supabase Auth email OTP verification
- Unique referral code per member
- +10 points for a verified referral, server-side only
- Anti-abuse fingerprint + duplicate referral checks + API rate limiting
- Ledger-based points history
- Purchase points: +1 per 1,000 IQD when an authenticated order is marked completed by admin
- Review: +100 (only from the admin approval path)
- Daily check-in: +10, max 7 per week
- Reward catalog with inventory and code inventory for gift cards/discounts
- Transactional redemption RPC with points deduction and cooldown
- Weekly referral leaderboard
- Starter / Fan / Pro / Elite levels based on lifetime points
- Server-side Lucky Spin, one spin per user per day
- Admin controls for rewards, inventory, gift-card codes and redemption fulfillment

## Supabase setup

1. Run the full `supabase-schema.sql` in the Supabase SQL editor.
2. Configure Vercel environment variables from `.env.example`.
3. `NEXT_PUBLIC_SUPABASE_ANON_KEY` must be the public anon/publishable key only. Never use the service-role key in browser code.
4. Enable Email OTP in Supabase Auth and configure your production Site URL / redirect settings.
5. Add gift-card codes from `/admin.html` before making gift-card rewards active.

## Security

The browser never has authority to increment points or choose a Lucky Spin outcome. Points, referral completion, redemptions and spins are validated in Postgres RPCs behind the server API.

The service-role key belongs only in Vercel server environment variables. If an old service-role key was ever pasted into chat, source control or client code, rotate it before production deployment.
