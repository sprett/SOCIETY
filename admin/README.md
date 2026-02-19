# Admin Dashboard

Browser-based admin dashboard for SOCIETY. Uses the same Supabase project as the main app.

## Setup

1. Copy `.env.example` to `.env.local`.
2. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` to the same values as the iOS app (see `SOCIETY/Info.plist` or Supabase Dashboard → Project Settings → API).
3. Run the admin SQL migration (see repo root: `supabase_admin_schema.sql` or `supabase/migrations/`) so that `profiles` has `role` and `created_at`, and `get_admin_stats()` exists. Set your profile to `role = 'admin'` in the Supabase Dashboard or via SQL.

## Development

```bash
npm install
npm run dev
```

## Build

```bash
npm run build
```

Output is in `dist/`. Deploy to your host (e.g. Vercel, Netlify) and point `admin.xxxxx.no` to it. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in your deployment environment (same as the iOS app).

## Access

Only users with `profiles.role = 'admin'` can use the dashboard. Others see "Access denied" after signing in. Sign in is email/password only (Supabase Auth).
