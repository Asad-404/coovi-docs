# COOVI Quick Status

Last updated: 2026-10-13. All dev servers are **stopped**; nothing is running.
Start here when resuming. API contract: `API_ENDPOINTS.md`. Go-live checklist: `docs/GO_LIVE_CHECKLIST.md`. Missing business features: `docs/FEATURE_GAPS.md`.

## Waiting on you

1. **Delete the old branches yourself** (Claude's delete was blocked on 2026-10-12). Every branch other than `master` in all three repos is the exact head of a merged pull request (checked 2026-10-12), so none holds unmerged work. See "Old branches to delete" below.
2. **Delete the demo data yourself** (Claude's delete was blocked): product `test-saree` ("Updated Test Saree") and order `ORD-20260920-814` ("Smoke Test"). Use the admin panel for the product; the order needs Atlas (the admin has no delete-order button). Order `ORD-20260919-558` ("Test Customer") also looks like test data.
3. **Policy pages: add your real terms** (delivery time; no returns after delivery, decided 2026-10-13). See "Policy pages" below.
4. **Production setup, three steps still open.** Secrets go straight into the Render dashboard, never into the chat.
   - Production database: in Atlas, create a new DB user (for example `coovi_prod`) with read/write on a new database named `coovi-prod` only, and keep the connection string ready.
   - Production secrets, saved in a password manager: a new `JWT_SECRET` (`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`), a production admin email and a strong admin password.
   - Business details to tell Claude (not secrets): the real WhatsApp number, the delivery fees in BDT (inside Dhaka city, and outside Dhaka including suburbs) and the production admin email.
5. WhatsApp placeholder `8801700000000` stays for now (owner decision 2026-10-07).
6. Optional: connect the private `Asad-404/coovi-docs` repository to the Claude Project as knowledge, and use its sync button after doc changes.

## Docs repository

The workspace root is the private `Asad-404/coovi-docs` repository (branch `main`, set up and merged 2026-10-12, pull request #1). It tracks only the root documents, `docs/` and `tools/`; the three app folders are ignored. The 13 planning files from 2026-09-17 were removed and stay in the Git history (commit `79758b1`). Doc changes go through a branch and pull request like the apps.

Removed 2026-10-13 because they were out of date, and still in the Git history: `DEPLOYMENT_PLAN.md` (the apps are deployed; see "Live deployment"), `docs/PROGRESS.md` (old task log and learning notes) and `docs/AIDLC_TODO.md` (its open steps are item 4 above). To read one again: `git show 300b9a2:docs/PROGRESS.md`.

## Old branches to delete

Git reports these as unmerged only because the pull requests were squash-merged or the branch was merged with a merge commit on GitHub. GitHub keeps each pull request's commits, so a deleted branch can be restored from its pull request page.

- `coovi-storefront` local: `claude/phase1-a11y-fixes`, `claude/phase2-design-refinements`, `feat/diponty-inspired-storefront-ui`, `fix/cart-open-shift-and-pointer`, `feature/cloudinary-image-host`. Remote: the same five plus `ccr-1cd6ed7a-xy0mle`, `ccr-a9c4492e-bz5894`, `claude/add-test-coverage`.
- `coovi-api` local: `ci/add-workflow`, `feat/redesign-sale-pricing-launch-prep`, `feature/cloudinary-upload-signature`. Remote: the same three plus `ccr-1cd6ed7a-xy0mle`, `ccr-a9c4492e-bz5894`, `ccr-f8eafd56-jah2yx`.
- `coovi-admin` local: `chore/vercel-spa-rewrite`, `ci/add-workflow`, `feat/redesign-sale-pricing-launch-prep`, `feature/cloudinary-photo-upload`. Remote: the same four plus `ccr-1cd6ed7a-xy0mle`, `ccr-a9c4492e-bz5894`, `ccr-f8eafd56-jah2yx`.

Local: `git branch -D <name>`. Remote: `git push origin --delete <name>`, or the Branches page on GitHub.

## Live deployment

- API: https://coovi-api.onrender.com (Render free plan, deployed 2026-10-07; `/health` returns ok). Build command `pnpm install --frozen-lockfile --prod=false && pnpm build`, start `node dist/index.js`.
- It uses the **dev** Atlas database for now (owner's choice, to test first). Switching `MONGODB_URI` to `coovi-prod` later gives an empty database: the admin is created from `ADMIN_EMAIL` / `ADMIN_PASSWORD` on first boot and products must be re-added through the admin. Changing `ADMIN_PASSWORD` on Render later does not change an existing admin's password.
- Storefront: https://coovi-storefront.vercel.app and admin: https://coovi-admin.vercel.app (Vercel Hobby, deployed 2026-10-07 from `master`; every merge to `master` redeploys). Checked 2026-10-07: products load, canonical and sitemap use the real address, admin deep links work, API allows both origins.
- `CORS_ORIGINS` on Render matches the two Vercel addresses. Vercel env: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL` (storefront), `VITE_API_URL` (admin); a change needs a redeploy.
- The site is public and search engines may index it while it still has some stock photos, the placeholder WhatsApp number and dev data.

## Where we are

All work is merged into `master` on GitHub, no pull request is open, and local `master` matches `origin/master` with a clean working tree in all three repos (checked 2026-10-12).

| Repo | Merged pull requests | Open |
|---|---|---|
| `coovi-api` | #1 sale pricing and hardening, #2 forward-only order status and admin order edits, #3 endpoint alignment, #4 PR template, #5 CI, #6 Cloudinary upload signature | none |
| `coovi-admin` | #1 redesign extras, #2 theme, order flow, filters, tests, #3 products switched off for sale, #4 PR template, #5 CI, #6 Vercel SPA rewrite, #7 photo upload button | none |
| `coovi-storefront` | #1 tests and CI, #2 redesign, #3 accessibility fixes, #4 Phase 2 design, #5 API limits and availability, #6 PR template, #7 cart-open page jump and pointer cursor, #8 Cloudinary image host | none |

Verified 2026-10-07 by running them: `coovi-api` typecheck and 79 tests; `coovi-admin` lint, build and 29 tests; `coovi-storefront` lint, typecheck and 82 tests (on the Phase 2 branch). Re-run 2026-10-12 on the Cloudinary branches: `coovi-api` typecheck and 84 tests; `coovi-admin` lint, build and 38 tests; `coovi-storefront` lint, typecheck and 84 tests. `pnpm build` for the storefront has still not been run.

All three apps work end to end. The storefront was redesigned to follow the Diponty (diponty.com) layout with Coovi's own branding.

| App | Port | Stack |
|---|---|---|
| `coovi-api` | 5000 | Express 5, TypeScript, Mongoose, MongoDB Atlas |
| `coovi-storefront` | 3000 | Next.js 16, React 19, Tailwind 4, Zustand |
| `coovi-admin` | 5173 | Vite, React 19, MUI 9, React Query 5 |

## Done this session

- **Storefront redesign** (desktop 1440 and phone 375 checked with screenshots): top bar, header with MENU on mobile, announcement strip, hero, promo, New Arrivals, All Products, Why Coovi, footer.
- **Pages:** `/shop` (sort, Load More), `/sale`, product detail (gallery, quantity + Add to cart, COD note, accordions, tabs, related products), empty-cart state, cart drawer. Header and mobile menu have search.
- **Sale pricing:** API `compareAtPrice` + `GET /products?onSale=true`; admin "Original price" field and On-sale chip; storefront Sale badges and struck-through prices. Orders still charge `price`.
- **Brand:** navy `#0C2953` + cyan `#06B5E4` palette from the logo (tokens in `coovi-storefront/app/globals.css`), text-recreated wordmark (`components/Logo.tsx`), `C.` favicon (`app/icon.svg`), Nunito + Inter fonts, light-only theme. Admin MUI theme uses the same colours.
- **Fixes:** page was 2x too wide on phones (closed cart drawer); cart drawer was clipped to the header (now portaled to `<body>`).
- **Docs:** `API_ENDPOINTS.md` recreated from the real routes; this file rewritten.
- **Photo upload (2026-10-12):** admin "Upload photos" button sends images straight to Cloudinary using a signature from `POST /api/uploads/signature`; the storefront allows `res.cloudinary.com`. Product `images` is still a list of URLs, so pasted links keep working.

## Data lives in the database, not the seed

The dev Atlas DB holds 26 products and 6 marked on sale. Most still have free Pexels photos (20 added through the admin API, 6 existing ones re-imaged); from 2026-10-12 the owner is replacing them with real photos stored on Cloudinary. `coovi-api/src/seed.ts` is stale and does **not** contain them, so re-running seed would not reproduce this data. Do not run seed unless you intend to replace it. A demo order (`ORD-20260920-814`, phone `01712345678`) also exists.

## Admin and API extras (done 2026-10-04, tests pass)

- API: `PATCH /api/auth/password` with 5 new tests in `coovi-api/tests/auth.test.ts`; duplicate `orderNumber` index removed (the Mongoose warning is gone).
- Admin: Change password dialog (top bar), Orders CSV export (respects filters, Excel-safe), Print slip button in the order dialog (invoice + packing list with COD amount), dashboard list of low-stock products linking to the edit form.

## API production hardening (done 2026-10-04, tests pass)

- In production the server refuses to start unless `MONGODB_URI`, a `JWT_SECRET` of 32+ characters, real (non-localhost) `CORS_ORIGINS` and a non-weak `ADMIN_PASSWORD` are set (`src/config/env.ts`; development only warns).
- `trust proxy` is on in production (1 hop, override with `TRUST_PROXY`), so Render does not make every visitor share one rate-limit bucket.
- `GET /health` checks the database connection (200 or 503); Render can keep using `GET /`. Tests in `coovi-api/tests/hardening.test.ts`.

## SEO, sharing and AI-crawler readiness (done 2026-10-04, branch feat/diponty-inspired-storefront-ui)

- Per-page titles (`Page | Coovi`), canonical links, Open Graph + Twitter tags, default 1200x630 share card (`app/opengraph-image.tsx`), `apple-icon`, web manifest, theme colour.
- Structured data: Product + Offer + BreadcrumbList on product pages, Organization + WebSite (search action) on the home page (`components/JsonLd.tsx`).
- `robots.txt` (blocks cart/checkout/track-order/order pages, names search and AI crawlers), `sitemap.xml` (home, shop, sale, about, contact, up to 50 products), `/llms.txt` (live product list for AI assistants).
- Search results and `?page=` pages are `noindex,follow`; cart, checkout and track-order are `noindex`.
- **Set `NEXT_PUBLIC_SITE_URL` (real https address, no trailing slash) in Vercel before the first production build**, or canonical, sitemap and share links point to localhost. Template: `coovi-storefront/.env.example`.
- In `next dev` the share image address shows `localhost`; production uses `NEXT_PUBLIC_SITE_URL` (checked in Next source).
- Still to do for SEO: submit the sitemap in Google Search Console once the domain is live; real product photos and descriptions help rankings most.

## Not verified yet

- `pnpm build` for the storefront (API and admin tests, admin build and storefront tests all passed on 2026-10-07).
- Real-phone check; checkout and order-confirmation pages were restyled by colour only.

## Backlog (not built yet), in suggested order

Admin features have a full implementation plan in `docs/ADMIN_FEATURE_PLAN.md` (written 2026-10-12, 18 features in 6 phases, nothing built yet).

0. Before launch (small): real WhatsApp number; owner review of the policy wording (below); replace remaining placeholder copy.
1. Order notifications to the owner (email, SMS or WhatsApp). Nothing alerts you today.
2. Done, merged and live 2026-10-12: admin "Upload photos" button, stored on Cloudinary's free plan (cloud `ebhb5jfl`, folder `coovi/products`). `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY` and `CLOUDINARY_API_SECRET` are set in `coovi-api/.env` and on Render; without them the button reports that upload is not configured. Owner tested an upload locally and on the live admin. Still open: deleting a product leaves its photos on Cloudinary.
3. Delivery fee by area: built, in review 2026-10-13 (coovi-api#14, coovi-admin#16, coovi-storefront#15). District dropdown at checkout; Dhaka city pays the inside fee, Dhaka suburbs and other districts the outside fee. Fees are placeholders (70 / 130) until you set `DELIVERY_FEE_INSIDE_DHAKA` and `DELIVERY_FEE_OUTSIDE_DHAKA` on Render. Merge the API first.
5. Admin: add a second admin account (change password is done).
6. Admin orders: real pagination (lists load 100). Internal notes and change history are built and awaiting merge (coovi-api#16, coovi-admin#10).
8. Categories (admin list + storefront category pages); everything is "Saree" now.
9. Discount codes; reviews, wishlist, back-in-stock; Google structured data on product pages.
10. Before launch: everything in `docs/GO_LIVE_CHECKLIST.md` (written 2026-10-13: production database, seed guard, backups, API that stays awake, storefront rate limit, order alerts, order lookup hardening, hosting terms, domain, error tracking, uptime alerts; security review items 26 and 29 to 37 added 2026-10-13, with the Next.js upgrade (item 29) in Priority 1).
11. Optional: Diponty-style product attributes (color, fabric, work, length), hero banners managed from admin, Bengali copy, icon on mobile header.

## Policy pages (done 2026-10-04): owner must review

`/return-policy`, `/delivery-policy` (shows the live delivery fee), `/privacy-policy`, `/terms` and a branded 404 (`app/not-found.tsx`) exist, are in the footer, sitemap, `llms.txt`, checkout and product page. The wording only states what the shop actually does (COD, flat fee, guest checkout, check parcel before paying) and deliberately has **no deadlines, refund method or delivery-time numbers**. Please add your real terms (return window in days, how refunds are paid, delivery time) and have the terms/privacy text checked if you need it to be legally binding. Content lives in `coovi-storefront/app/<page>/page.tsx`; the shared layout is `components/PolicyPage.tsx` (`POLICY_UPDATED` date).

## Placeholders to replace before launch

- WhatsApp number `8801700000000` (header, contact page, product page). Once the shop settings pull requests (coovi-api#22, coovi-admin#14, coovi-storefront#13) are merged, change it on the admin Settings page; no code change or redeploy needed.
- Pexels stock photos (replace with real saree photos using the admin "Upload photos" button); the logo is a text recreation, so use an SVG export of the real logo if available.
- Generic care-guide copy on the product tabs; the delivery and "check before you pay" accordions now link to the policy pages.
- Delete the `test-saree` demo product and the demo order.
- Dev admin credentials (`ADMIN_EMAIL` / `ADMIN_PASSWORD` in `coovi-api/.env`, gitignored) and `CORS_ORIGINS` for production.

## Design reference workflow

`node tools/screenshot.mjs <url> <out.png> [width] [maxHeight]` captures any page at phone (375) or desktop (1440) width with real device emulation (uses the Playwright Chromium cache). Optional env: `Y=<offset>` to crop from a vertical offset, `EVAL=<js>` to run a snippet first, for example to click buttons. Diponty is a layout reference only: use its structure, never its logo, text or photos.

## Known notes

- `/shop` Load More asks for `12 x page` products at once, so it caps at the API limit of 50.
- Next 16 returns HTTP 200 for `notFound()` once streaming starts (soft 404); product pages carry `noindex` as mitigation.
- Claude may run tests, lint and builds and push feature branches (owner said yes 2026-10-07); dev servers, seed scripts and `master` stay with the owner (see root `CLAUDE.md`).

## Manual resume commands

```bash
cd /d/Work/COOVI/coovi-api && pnpm dev
cd /d/Work/COOVI/coovi-storefront && pnpm dev
cd /d/Work/COOVI/coovi-admin && pnpm dev
curl http://localhost:5000/api/products
```

Quick health check once running: `curl http://localhost:5000/api/orders/delivery-fee` should return `{"success":true,"data":{"deliveryFee":60}}`.
