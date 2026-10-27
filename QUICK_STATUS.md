# COOVI Quick Status

Last updated: 2026-10-20. All dev servers are **stopped**; nothing is running.
Start here when resuming. API contract: `API_ENDPOINTS.md`. Go-live checklist: `docs/GO_LIVE_CHECKLIST.md`. Missing business features: `docs/FEATURE_GAPS.md`.

## Waiting on you

1. **Delete the old branches yourself** (Claude's delete was blocked on 2026-10-12). Every branch other than `master` in all three repos is the exact head of a merged pull request (checked 2026-10-12), so none holds unmerged work. See "Old branches to delete" below.
2. **Delete the demo data yourself** (Claude's delete was blocked): product `test-saree` ("Updated Test Saree") and order `ORD-20260920-814` ("Smoke Test"). Use the admin panel for the product; the order needs Atlas (the admin has no delete-order button). Order `ORD-20260919-558` ("Test Customer") also looks like test data.
3. **Policy pages: add your real terms** (delivery time; no returns after delivery, decided 2026-10-13). See "Policy pages" below.
4. **Production setup, three steps still open.** Secrets go straight into the Render dashboard, never into the chat.
   - Production database: in Atlas, create a new DB user (for example `coovi_prod`) with read/write on a new database named `coovi-prod` only, and keep the connection string ready.
   - Production secrets, saved in a password manager: a new `JWT_SECRET` (`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`), a production admin email and a strong admin password.
   - Real WhatsApp number: set it yourself on the admin Settings page (no code change). The delivery fees were set on Render on 2026-10-13.
5. WhatsApp placeholder `8801700000000` stays for now (owner decision 2026-10-07).
7. **Your go-live items** (database, backups, paid plans, domain, registration) are listed in `docs/GO_LIVE_CHECKLIST.md`, marked **You**. Owner decision 2026-10-15: leave them for now; Claude works on items with no blockers.
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
- `CORS_ORIGINS` on Render matches the two Vercel addresses. Vercel env: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL`, `NEXT_PUBLIC_META_PIXEL_ID` (storefront, pixel off while empty), `VITE_API_URL` (admin); a change needs a redeploy.
- The site is public and search engines may index it while it still has some stock photos, the placeholder WhatsApp number and dev data.

## Where we are

Checked 2026-10-15 against GitHub. Built and merged since 2026-10-12, all live on `master`:

- **Orders:** pre-orders for out-of-stock sarees, new-order email alerts (Resend), private notes and change history, refused-at-door `Returned` status with restock, manual order entry (Facebook, WhatsApp, phone), delivery fee by district, courier cash (COD) tracking on the "Courier payments" page.
- **Shop settings page:** WhatsApp number, support phone, announcement and low-stock limit, edited in the admin.
- **Safety:** seed guard, harder-to-guess order numbers with one-phone lookup, storefront server rate limit and caching, Next.js 16.3.8, security headers on the admin and storefront, and the 2026-10-13 security review fixes.

Open pull requests:

| Pull requests | What | Waiting on |
|---|---|---|
| coovi-api#18, coovi-admin#12, coovi-docs#11 | Book parcels with Steadfast and save the tracking code | Your Steadfast merchant account and API keys |
| coovi-api#15 (draft) | SMS the customer their order number | Your choice of SMS company |

| App | Port | Stack |
|---|---|---|
| `coovi-api` | 5000 | Express 5, TypeScript, Mongoose, MongoDB Atlas |
| `coovi-storefront` | 3000 | Next.js 16, React 19, Tailwind 4, Zustand |
| `coovi-admin` | 5173 | Vite, React 19, MUI 9, React Query 5 |

## Earlier work (2026-10-04 to 2026-10-12)

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
- Product link previews (Facebook, Messenger, WhatsApp; in review 2026-10-20, branch `claude/social-share-previews-kg0ucw`): each product can have a **share image** uploaded in the admin product form. Make it **1200 x 630 px, JPG, under 300 KB**, with the saree and any text in the middle 630 x 630 square (WhatsApp and small Messenger previews crop to a square). Without one the first product photo is used, which tall saree photos crop badly. The preview text starts with the price and stock (`shareDescription` in `coovi-storefront/lib/utils.ts`).
- Checking a product link before sharing: open https://developers.facebook.com/tools/debug/, paste the product address, press **Debug**. It shows the picture, title and text Facebook will use. After changing a product's image or text, press **Scrape Again**, otherwise Facebook can keep showing its old copy for weeks. WhatsApp keeps its own copy too; a link shared there before the change can keep the old preview.
- Still to do for SEO: submit the sitemap in Google Search Console once the domain is live; real product photos and descriptions help rankings most.

## Not verified yet

- `pnpm build` for the storefront (API and admin tests, admin build and storefront tests all passed on 2026-10-07).
- Real-phone check; checkout and order-confirmation pages were restyled by colour only.

## Backlog (not built yet), in build order

Approved by the owner on 2026-10-15 (plan in the project files, `reviews/PLAN_UNBLOCKED_FEATURES_2026-10-15.md`). Each step is its own set of pull requests.

1. Done (merged 2026-10-15: coovi-api#31, coovi-admin#25): roles (owner, manager, staff, viewer) with per-person View and Edit access edited on the Team page, and sign out everywhere when a password changes (plan feature 13, checklist item 18).
2. Done (merged 2026-10-15: coovi-api#32, coovi-admin#26): statistics dashboard with cost price and profit (plan feature 11). `GET /api/stats` counts on the server for a date range; money cards (delivered revenue, profit, average order, cash with the courier) only for people with money access; best sellers, refused rate, orders by district and source. Products get a cost price field; orders placed before a cost is set show profit as unknown.
3. Done (merged 2026-10-15: coovi-api#33, coovi-admin#27): admin orders load one page at a time (25, 50 or 100), with search by order number, name or phone, and status, area, source and date filters done by the API; CSV export still includes every matching order (plan feature 12).
4. Done (merged 2026-10-15, coovi-api#34, coovi-admin#28): a Customers page (everyone who has ordered, by phone, with delivered, refused and cancelled counts) and a block list (plan feature 8). Owner decision 2026-10-15: a blocked phone's order is accepted but shown in red in the admin for a confirmation call, not refused. The order window also shows that number's history.
5. Done (merged 2026-10-15: coovi-api#35, coovi-storefront#26): small cleanups: delete a product's photos from Cloudinary with the product (checklist item 28); move the phone number out of the order-confirmation link (checklist item 37).

Not now (owner decision 2026-10-15): categories, saree details (fabric, colour, work) and shop filters (plan features 7 and 9a).

Waiting on the owner: Steadfast booking and the customer tracking link (Steadfast account), customer SMS (SMS company), error tracking (free Sentry account), visitor analytics, the Meta Pixel ID (pixel built, checklist item 38; the server copy waits until ads start), and the **You** items in `docs/GO_LIVE_CHECKLIST.md`.

Later (P3): discount codes, bulk actions, stock history, homepage banner from the admin, product variants, reviews and back-in-stock, wishlist, customer accounts, online payment, WhatsApp alerts, Bengali copy, icon on the mobile header.

## Policy pages (done 2026-10-04): owner must review

`/return-policy`, `/delivery-policy` (shows the live delivery fee), `/privacy-policy`, `/terms` and a branded 404 (`app/not-found.tsx`) exist, are in the footer, sitemap, `llms.txt`, checkout and product page. The wording only states what the shop actually does (COD, flat fee, guest checkout, check parcel before paying) and deliberately has **no deadlines, refund method or delivery-time numbers**. Please add your real terms (return window in days, how refunds are paid, delivery time) and have the terms/privacy text checked if you need it to be legally binding. Content lives in `coovi-storefront/app/<page>/page.tsx`; the shared layout is `components/PolicyPage.tsx` (`POLICY_UPDATED` date).

## Placeholders to replace before launch

- WhatsApp number `8801700000000` (header, contact page, product page). Change it on the admin Settings page; no code change or redeploy needed.
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
