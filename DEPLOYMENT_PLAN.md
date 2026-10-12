# 🚀 DEPLOYMENT_PLAN.md — COOVI
**Status:** ⏸️ DEFERRED (2026-09-20) — deployment paused by decision; exploration findings preserved here so nothing is lost. All findings verified against actual code (file:line references). Pick up from this doc when ready.

---

## Overview
- **Order matters:** API first → storefront → admin (both frontends need the API's public URL as an env var)
- **Platforms:** API → Render free tier (recommended) or Railway · storefront + admin → Vercel (free)
- **Database:** MongoDB Atlas is already cloud-hosted (M0, network access 0.0.0.0/0) — nothing to deploy, and the open allowlist already covers hosts with dynamic egress IPs

## Platform comparison — API host
| | Render free tier | Railway |
|---|---|---|
| Cost | $0 forever | $5 one-time trial credit, then $5/mo Hobby plan (card required) |
| Sleeps? | Yes — 15 min idle, ~30-60s cold start on first request | No, always on |
| pnpm support | Yes | Yes |
| Egress IPs | Dynamic | Static IPs available |
| Verdict | Start here while learning/demoing | Upgrade when the store goes live and cold starts cost customers |

---

## Step 0 — Pre-deploy code changes (coovi-api, do BEFORE deploying anything)
1. **CORS whitelist** — replace `app.use(cors())` (src/index.ts:17, currently reflects any origin) with an explicit origin list, e.g. `cors({ origin: process.env.CLIENT_ORIGINS?.split(',') ?? false })`, set to the two Vercel URLs
2. **Remove dead dependencies** — `bcrypt` + `@types/bcrypt` (code uses bcryptjs everywhere), `ts-node-dev` (scripts use tsx), `mongodb-connection-string-url` (never imported):
   `pnpm remove bcrypt @types/bcrypt mongodb-connection-string-url && pnpm remove -D ts-node-dev`
3. Commit + push (run git yourself, per your workflow)

## Step 1 — Deploy coovi-api
- Repo: github.com/Asad-404/coovi-api · uses pnpm (packageManager field set)
- **Build command:** `pnpm install --frozen-lockfile && pnpm build` · **Start command:** `pnpm start` (runs `node dist/index.js` — CommonJS output, verified)
- **Health check path:** `/` (returns 200 JSON, src/index.ts:22-33)
- **Env vars to set in the host dashboard** (the gitignored `.env` never ships):

| Var | Value |
|---|---|
| MONGODB_URI | from coovi-api/.env |
| JWT_SECRET | from coovi-api/.env — or generate a fresh one for prod |
| ADMIN_EMAIL | admin@coovi.com (or a new prod address) |
| ADMIN_PASSWORD | **generate a strong one — dev default admin123 must NOT go to prod** |
| NODE_ENV | production |
| CLIENT_ORIGINS | (after Steps 2+3: both Vercel URLs, comma-separated) |

`PORT` is provided by the platform automatically (src/index.ts:14 already reads it).

- **Already handled in code:** binds all interfaces by default; graceful SIGINT/SIGTERM shutdown (src/index.ts:75-83); admin auto-seeds only when zero admins exist (src/index.ts:58-66) — note: changing ADMIN_PASSWORD env later does NOT update an existing admin; error responses omit stack traces when NODE_ENV ≠ development (safe by default)
- **Known behavior:** no app-level DB retry — boot fails after ~10s if Atlas is unreachable; the host's crash-restart acts as the retry. pnpm installs devDeps by default so TypeScript is available for the build.

## Step 2 — Deploy coovi-storefront → Vercel
- Import repo github.com/Asad-404/coovi-storefront; Next.js auto-detected
- **Required env var (Production):** `NEXT_PUBLIC_API_URL=https://<api-host>/api` — the fallback is hardcoded `http://localhost:5000/api` (lib/api.ts:3) and it is **inlined at build time** into the client-side checkout fetch (app/checkout/page.tsx:9), so it MUST be set before the first Vercel build or checkout silently posts to localhost
- Images: next/image remotePatterns already configured (res.cloudinary.com for admin uploads, plus images.pexels.com, picsum.photos and images.unsplash.com; next.config.ts). If the admin later adds images from other domains, add them to remotePatterns
- Admin photo upload needs `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET` set on the API host (Render); the storefront and admin need no Cloudinary variables
- No rewrites or output config needed

## Step 3 — Deploy coovi-admin → Vercel
- Import repo github.com/Asad-404/coovi-admin; Framework preset: **Vite**; build command `pnpm build` (tsc -b && vite build); output directory `dist`
- **Required: create vercel.json** (does not exist today) for React Router deep links — without it, refreshing or deep-linking `/products` returns 404:
  ```json
  { "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }] }
  ```
- **Required env var:** `VITE_API_URL=https://<api-host>/api` — inlined at build time by Vite (src/api/client.ts:4); the localhost fallback breaks in prod

## Step 4 — Post-deploy verification checklist
1. `curl https://<api-host>/` → 200 JSON info
2. Storefront: browse → search → add to cart → checkout → order-confirmation page loads
3. Admin: login with prod creds → the new order appears → change status → stock updates on Products tab
4. Browser console: no CORS errors (if any: CLIENT_ORIGINS must exactly match the Vercel URLs — https, no trailing slash)
5. Deep-link refresh on admin `/products` → page loads, not 404

---
*Source: two exploration passes over all three codebases on 2026-09-20 (API report + frontends report).*
