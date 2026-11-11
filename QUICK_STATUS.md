# COOVI Quick Status

Last updated: 2026-11-02. All dev servers are **stopped**; nothing is running.
Start here when resuming. API contract: `API_ENDPOINTS.md`. Go-live checklist: `docs/GO_LIVE_CHECKLIST.md`. Missing business features: `docs/FEATURE_GAPS.md`.

## Waiting on you

1. Done 2026-11-02: unused branches deleted, locally and on GitHub, in all four repos. Each one was the head of a merged pull request or already contained in `master`, except `feat/live-product-price-stock` (coovi-storefront#49, closed on purpose), which can be restored from that pull request. The only branch kept besides `master` is `claude/project-thread-qolyc8` (coovi-api#15, closed). Storefront pull requests are squash-merged, so a merged branch still shows commits not on `master`: before deleting, compare by pull request state, not commit count.
2. Done 2026-10-27: demo data deleted. Orders `ORD-20260920-814` ("Smoke Test") and `ORD-20260919-558` ("Test Customer") are gone; the `test-saree` product was already gone.
3. **Policy pages: add your real terms** (delivery time; no returns after delivery, decided 2026-10-13). See "Policy pages" below.
4. **Production setup, three steps still open.** Secrets go straight into the Render dashboard, never into the chat.
   - Production database: in Atlas, create a new DB user (for example `coovi_prod`) with read/write on a new database named `coovi-prod` only, and keep the connection string ready.
   - Production secrets, saved in a password manager: a new `JWT_SECRET` (`node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`), a production admin email and a strong admin password.
   - Real WhatsApp number: set it yourself on the admin Settings page (no code change). The delivery fees were recorded as set on Render on 2026-10-13. **To confirm:** on 2026-11-01 the live API returned 70 and 130, the same as the placeholders, so check these are your real fees.
5. WhatsApp placeholder `8801700000000` stays for now (owner decision 2026-10-07).
6. Optional: connect the private `Asad-404/coovi-docs` repository to the Claude Project as knowledge, and use its sync button after doc changes.
7. **Your go-live items** (database, backups, paid plans, domain, registration) are listed in `docs/GO_LIVE_CHECKLIST.md`, marked **You**. Owner decision 2026-10-15: leave them for now; Claude works on items with no blockers.
8. Done 2026-10-31: the owner deleted all existing orders, so none were carried over to the new 6-character numbers such as `K7M3QX`. **Still to check:** any courier payments recorded for those orders, which keep their own copy of the old numbers.
9. Done 2026-11-02: `NEXT_PUBLIC_META_PIXEL_ID` removed from Vercel. Owner decision 2026-11-01: no ads, so no ad tracking.

## Docs repository

The workspace root is the private `Asad-404/coovi-docs` repository (branch `master`, renamed from `main` on 2026-10-27; set up and merged 2026-10-12, pull request #1). It tracks only the root documents, `docs/` and `tools/`; the three app folders are ignored. The 13 planning files from 2026-09-17 were removed and stay in the Git history (commit `79758b1`). Doc changes go through a branch and pull request like the apps.

Removed 2026-10-13 because they were out of date, and still in the Git history: `DEPLOYMENT_PLAN.md` (the apps are deployed; see "Live deployment"), `docs/PROGRESS.md` (old task log and learning notes) and `docs/AIDLC_TODO.md` (its open steps are item 4 above). To read one again: `git show 300b9a2:docs/PROGRESS.md`.

## Live deployment

- API: https://coovi-api.onrender.com (Render free plan, deployed 2026-10-07; `/health` returns ok). Build command `pnpm install --frozen-lockfile --prod=false && pnpm build`, start `node dist/index.js`.
- It uses the **dev** Atlas database for now (owner's choice, to test first). Switching `MONGODB_URI` to `coovi-prod` later gives an empty database: the admin is created from `ADMIN_EMAIL` / `ADMIN_PASSWORD` on first boot and products must be re-added through the admin. Changing `ADMIN_PASSWORD` on Render later does not change an existing admin's password.
- Storefront: https://coovi-storefront.vercel.app and admin: https://coovi-admin.vercel.app (Vercel Hobby, deployed 2026-10-07 from `master`; every merge to `master` redeploys). Checked 2026-10-07: products load, canonical and sitemap use the real address, admin deep links work, API allows both origins.
- `CORS_ORIGINS` on Render matches the two Vercel addresses. Vercel env: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL` (storefront), `VITE_API_URL` (admin); a change needs a redeploy.
- The site is public and search engines may index it while it still has the placeholder WhatsApp number and dev data.

## Where we are

Checked 2026-10-15 against GitHub. Built and merged since 2026-10-12, all live on `master`:

- **Orders:** pre-orders for out-of-stock sarees, new-order email alerts (Resend), private notes and change history, refused-at-door `Returned` status with restock, manual order entry (Facebook, WhatsApp, phone), delivery fee by district, courier cash (COD) tracking on the "Courier payments" page.
- **Order tracking (coovi-storefront#32, merged 2026-10-31):** the Track Order form opens `/track-order/<number>` with status steps and the order details, instead of the "Order placed!" page. A wrong phone or unknown number says to check the details; the API being down or busy shows the error page.
- **Shop settings page:** WhatsApp number, support phone, announcement and low-stock limit, edited in the admin.
- **Safety:** seed guard, harder-to-guess order numbers with one-phone lookup, storefront server rate limit and caching, Next.js 16.3.8, security headers on the admin and storefront, and the 2026-10-13 security review fixes.
- **Order numbers (merged 2026-10-31: coovi-api#39, coovi-storefront#31, coovi-admin#31):** new orders get 6 random characters such as `K7M3QX` instead of `ORD-YYYYMMDD-XXXXXX`. There is no migration or lookup for old numbers, because the owner deleted the old orders. With `DELIVERY_FEE=60` in a local `coovi-api/.env`, 2 fee tests fail (`tests/orders.test.ts`, `tests/deliveryAreas.test.ts`) because they expect the default of 70; they pass with it blanked.
- **Storefront, merged 2026-10-31:** each page has its own loading skeleton (coovi-storefront#33). The home hero has a solid blue-grey background, three slanted photo panels and a light sweep (coovi-storefront#34).
- **Storefront, merged 2026-10-31 and 2026-11-01:** the collection moved from `/shop` to `/saree` (coovi-storefront#36), the cart drawer no longer shakes (#37), pages that set their own Open Graph keep the share card (#38), the product image zooms on hover (#39), and above-the-fold photos load eagerly (#40).
- **Checkout, merged 2026-11-01 (coovi-storefront#41):** Inside Dhaka and Outside Dhaka radios with both fees sit in the order summary, with nothing preselected, and stay in step with the district. The address box is split into house and road, flat or floor, and area or thana, joined into the API's one `address` string. The place order button moved under the summary. No API change.
- **Load speed, merged 2026-11-01 and 2026-11-02:** the Meta Pixel is gone (coovi-storefront#43), the main product photo loads at high priority (#42), the ৳ sign is stored in the app and Bengali fonts are no longer preloaded (#44). Home and product pages are served from cache (#45, #47), the API is woken before Vercel builds (#46) and shop settings refresh every 5 minutes (#48). Results are in `docs/PLAN_PAGE_CACHING.md`: first byte is about 150 to 215 ms on home and 133 to 150 ms on product pages.
- **Storefront, merged 2026-11-02:** the header paints at once and the chat link goes to `/contact` until settings load (coovi-storefront#50), phones skip hover photos and the desktop hero is sharper (#51), checkout moves to current prices and says what changed (#52), and the privacy policy mentions the order phone cookie (#53).
- **Bangla font, merged 2026-11-02 (coovi-storefront#54):** Bangla text uses SolaimanLipi, except the saree names on the all sarees and new arrivals cards, which match Diponty: Inter for English and the device's own font for Bangla, so they look different from device to device. SolaimanLipi has one weight, so bold Bangla is faked by the browser.
- **Owner decisions 2026-11-02:** no browser call to the API for live price and stock on product pages (coovi-storefront#49, closed). Keep the page skeletons on home and product pages, so missing products keep returning 200 with `noindex`. The skeleton plan is dropped. No uptime monitor for now. Keep the announcement on and to one line. coovi-api#15 (customer SMS) is closed; its branch `claude/project-thread-qolyc8` is kept.
- **Order confirmation, merged 2026-11-11 (coovi-storefront#56):** `/order-confirmation/<number>` follows the order's current status instead of always saying "Order placed!": the heading changes (for example "Order on the way", "Order cancelled"), Cancelled and Returned get a grey ✕, the "we will call you" line shows only while Pending, and the status steps from the track-order page appear above the summary. Go-live checklist item 41. Any error loading the order still shows "not found" on this page, unlike the track-order page.
- **Products, merged 2026-11-01:** products can be saved as drafts and published later (coovi-api#41, coovi-admin#33). Publishing needs at least 3 photos and a share image, and opening a published product for editing asks for confirmation first (coovi-api#42, coovi-admin#34).

Open pull requests: none in any repo on 2026-11-02.

| App | Port | Stack |
|---|---|---|
| `coovi-api` | 5000 | Express 5, TypeScript, Mongoose, MongoDB Atlas |
| `coovi-storefront` | 3000 | Next.js 16, React 19, Tailwind 4, Zustand |
| `coovi-admin` | 5173 | Vite, React 19, MUI 9, React Query 5 |

## Phone admin (merged 2026-11-01, coovi-admin#32)

Owner decision 2026-11-01: there is no budget for a PC or laptop for now, so the admin must work from a phone. Under 900 px it has bottom tabs, cards instead of tables, Call and WhatsApp on every order and customer, and each order's next step as its main button, which asks before moving the order. Wider screens keep the tables, so a laptop can come back later.

## Earlier work (2026-10-04 to 2026-10-12)

- **Storefront redesign** (desktop 1440 and phone 375 checked with screenshots): top bar, header with MENU on mobile, announcement strip, hero, promo, New Arrivals, All Products, Why Coovi, footer.
- **Pages:** `/saree` (sort, Load More), `/sale`, product detail (gallery, quantity + Add to cart, COD note, accordions, tabs, related products), empty-cart state, cart drawer. Header and mobile menu have search.
- **Sale pricing:** API `compareAtPrice` + `GET /products?onSale=true`; admin "Original price" field and On-sale chip; storefront Sale badges and struck-through prices. Orders still charge `price`.
- **Brand:** navy `#0C2953` + cyan `#06B5E4` palette from the logo (tokens in `coovi-storefront/app/globals.css`), text-recreated wordmark (`components/Logo.tsx`), `C.` favicon (`app/icon.svg`), light-only theme. Fonts now: Hind Siliguri for text, Tiro Bangla for headings, SolaimanLipi for Bangla, Nunito for the wordmark only, Inter for saree card names only, and a small font of its own for the ৳ sign (`app/layout.tsx`). Admin MUI theme uses the same colours.
- **Fixes:** page was 2x too wide on phones (closed cart drawer); cart drawer was clipped to the header (now portaled to `<body>`).
- **Docs:** `API_ENDPOINTS.md` recreated from the real routes; this file rewritten.
- **Photo upload (2026-10-12):** admin "Upload photos" button sends images straight to Cloudinary using a signature from `POST /api/uploads/signature`; the storefront allows `res.cloudinary.com`. Product `images` is still a list of URLs, so pasted links keep working.

## Data lives in the database, not the seed

**To confirm:** on 2026-11-01 the live shop listed 6 products, 2 on sale, all with Cloudinary photos and none with a Pexels photo. Earlier notes recorded 26 products, 6 on sale and mostly Pexels photos. The public list leaves out drafts, so check the admin Products page to see whether the other 20 are drafts or were deleted. None of the 6 has 3 photos or a share image yet: they stay live, but changing their pictures or republishing them needs both. `coovi-api/src/seed.ts` is stale and does **not** contain them, so re-running seed would not reproduce this data. Do not run seed unless you intend to replace it. The demo orders `ORD-20260920-814` and `ORD-20260919-558` were deleted 2026-10-27.

The six saree names were shortened to one English word in the database for coovi-storefront#54 (for example "Rangila Crimson Handloom" to "Rangila"); slugs did not change. Shop search only looks at the English name, so searching "silk" or "maroon" no longer finds them. Nothing in the admin limits name length.

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
- `robots.txt` (blocks cart/checkout/track-order/order pages, names search and AI crawlers), `sitemap.xml` (home, saree, sale, about, contact, policy pages, every published product), `/llms.txt` (live product list for AI assistants).
- Search results and `?page=` pages are `noindex,follow`; cart, checkout and track-order are `noindex`.
- **Set `NEXT_PUBLIC_SITE_URL` (real https address, no trailing slash) in Vercel before the first production build**, or canonical, sitemap and share links point to localhost. Template: `coovi-storefront/.env.example`.
- In `next dev` the share image address shows `localhost`; production uses `NEXT_PUBLIC_SITE_URL` (checked in Next source).
- Product link previews (Facebook, Messenger, WhatsApp): each product can have a **share image** uploaded in the admin product form. Make it **1200 x 630 px, JPG, under 300 KB**, with the saree and any text in the middle 630 x 630 square (WhatsApp and small Messenger previews crop to a square). Without one the first product photo is used, which tall saree photos crop badly. The preview text starts with the price and stock (`shareDescription` in `coovi-storefront/lib/utils.ts`).
- Checking a product link before sharing: open https://developers.facebook.com/tools/debug/, paste the product address, press **Debug**. It shows the picture, title and text Facebook will use. After changing a product's image or text, press **Scrape Again**, otherwise Facebook can keep showing its old copy for weeks. WhatsApp keeps its own copy too; a link shared there before the change can keep the old preview.
- Still to do for SEO: submit the sitemap in Google Search Console once the domain is live; real product photos and descriptions help rankings most.

## Not verified yet

- coovi-storefront#54: lint, typecheck and tests pass, and desktop width was checked on the dev server. `pnpm build` was not re-run after the card name commit, and the card names were not viewed at phone width: their fit is calculated. Check them on a real phone.
- coovi-storefront#50 to #53: lint, typecheck, tests and build pass, and live checks on 2026-11-02 show layout shift 0, the sharper hero and the privacy text. Still to try by hand: the checkout price note (#52, change a price while an item is in the cart), and hover photos (#51, needs a live product with 2 or more photos). The white-page fix (#50) has not been seen with the API asleep.
- The wake-up script's line in the Vercel build log (coovi-storefront#46): only the owner can see it.
- How home and product pages behave while the API is asleep, including the first visit to a product added since the last deploy.

- Meta Pixel removal (coovi-storefront#43): tests, lint, typecheck and build pass, but Claude did not open it in a browser. After it deploys, check that the product page, add to cart, checkout and order confirmation still work, and that no request goes to Facebook.
- Checkout radios and address fields (coovi-storefront#41, merged 2026-11-01): tests, lint, typecheck and build pass, but Claude did not open it in a browser. At phone and desktop width, check the radios in the order summary, pick Inside Dhaka and then another district, and place one test order.
- Publish block on the product form (coovi-api#41, coovi-admin#33, merged 2026-11-01): tests, lint and build pass, but Claude did not open it in a browser. Save a draft, check it is missing from the shop, publish it, then unpublish it.
- Photo rules and edit confirmation (coovi-api#42, coovi-admin#34, merged 2026-11-01): tests, lint and build pass, but Claude did not open them in a browser. Try uploading a square photo, publishing with 2 photos and with no share image, then open a published product for editing and press both Go back and Edit product. Published products from before the rules keep working until their pictures are changed or they are republished.
- Phone admin (coovi-admin#32, merged 2026-11-01): checked at 375 px in headless Chrome with a fake API, not on a real phone or against the real API. On a phone, check Call and WhatsApp, photo upload, the keyboard with the Save bar, and Print slip.
- Track Order page (coovi-storefront#32): lint, typecheck, tests and build pass, but Claude did not open it in a browser. Submit the form once with the right phone and once with a wrong one.
- Order confirmation status (coovi-storefront#56, merged 2026-11-11): lint, typecheck and tests pass, but Claude did not open it in a browser. Place an order, then set it to Shipped and to Cancelled in the admin and reload the confirmation page each time.
- Real-phone check; the order-confirmation page was restyled by colour only.
- Product listing retry (coovi-storefront#58, merged TODO): lint, typecheck, tests and build pass. Click the "Try again" button when the API is unreachable.
- Admin clipboard/print errors (coovi-admin#38, merged TODO): lint, tests and build pass. Copy a tracking code on a device without clipboard permission; block pop-ups and click Print slip.

## Browser acceptance check — 2026-11-11

The items below require a real browser or device and cannot be verified from code. All are marked **not yet browser-verified** as of 2026-11-11. The owner will check them manually.

- Checkout area switching (Inside / Outside Dhaka radios), current-price change warning, and placing one test order
- Track Order: success path with the right phone, wrong-phone error path
- Order confirmation: behavior after an order status changes in the admin, and after an API outage
- Draft / publish / unpublish a product; photo count and share-image rules when publishing
- Manual order entry: district selection and delivery fee preview in the admin
- Steadfast courier booking and tracking status check
- Phone admin actions: Call, WhatsApp, photo upload, Save bar with the keyboard open, Print slip
- API asleep / wakeup behavior, and the first visit to a newly published product

## Backlog (not built yet), in build order

Approved by the owner on 2026-10-15 (plan in the project files, `reviews/PLAN_UNBLOCKED_FEATURES_2026-10-15.md`). Each step is its own set of pull requests.

1. Done (merged 2026-10-15: coovi-api#31, coovi-admin#25): roles (owner, manager, staff, viewer) with per-person View and Edit access edited on the Team page, and sign out everywhere when a password changes (plan feature 13, checklist item 18).
2. Done (merged 2026-10-15: coovi-api#32, coovi-admin#26): statistics dashboard with cost price and profit (plan feature 11). `GET /api/stats` counts on the server for a date range; money cards (delivered revenue, profit, average order, cash with the courier) only for people with money access; best sellers, refused rate, orders by district and source. Products get a cost price field; orders placed before a cost is set show profit as unknown.
3. Done (merged 2026-10-15: coovi-api#33, coovi-admin#27): admin orders load one page at a time (25, 50 or 100), with search by order number, name or phone, and status, area, source and date filters done by the API; CSV export still includes every matching order (plan feature 12).
4. Done (merged 2026-10-15, coovi-api#34, coovi-admin#28): a Customers page (everyone who has ordered, by phone, with delivered, refused and cancelled counts) and a block list (plan feature 8). Owner decision 2026-10-15: a blocked phone's order is accepted but shown in red in the admin for a confirmation call, not refused. The order window also shows that number's history.
5. Done (merged 2026-10-15: coovi-api#35, coovi-storefront#26): small cleanups: delete a product's photos from Cloudinary with the product (checklist item 28); move the phone number out of the order-confirmation link (checklist item 37).

Not now (owner decision 2026-10-15): categories, saree details (fabric, colour, work) and shop filters (plan features 7 and 9a).

Waiting on the owner: Steadfast booking and the customer tracking link (Steadfast account), customer SMS (SMS company; coovi-api#15 was closed unmerged, so it still has to be built), error tracking (free Sentry account), visitor analytics, and the **You** items in `docs/GO_LIVE_CHECKLIST.md`.

Later (P3): discount codes, bulk actions, stock history, homepage banner from the admin, product variants, reviews and back-in-stock, wishlist, customer accounts, online payment, WhatsApp alerts, Bengali copy, icon on the mobile header.

## Policy pages (done 2026-10-04): owner must review

`/return-policy`, `/delivery-policy` (shows the live delivery fee), `/privacy-policy`, `/terms` and a branded 404 (`app/not-found.tsx`) exist, are in the footer, sitemap, `llms.txt`, checkout and product page. The wording only states what the shop actually does (COD, delivery fee by area, guest checkout, check parcel before paying) and deliberately has **no deadlines, refund method or delivery-time numbers**. Please add your real terms (return window in days, how refunds are paid, delivery time) and have the terms/privacy text checked if you need it to be legally binding. Content lives in `coovi-storefront/app/<page>/page.tsx`; the shared layout is `components/PolicyPage.tsx` (`POLICY_UPDATED` date).

## Placeholders to replace before launch

- WhatsApp number `8801700000000` (header, contact page, product page). Change it on the admin Settings page; no code change or redeploy needed.
- The logo is a text recreation, so use an SVG export of the real logo if available.
- Generic care-guide copy on the product tabs; the delivery and "check before you pay" accordions now link to the policy pages.
- Dev admin credentials (`ADMIN_EMAIL` / `ADMIN_PASSWORD` in `coovi-api/.env`, gitignored) and `CORS_ORIGINS` for production.

## Design reference workflow

`node tools/screenshot.mjs <url> <out.png> [width] [maxHeight]` captures any page at phone (375) or desktop (1440) width with real device emulation (uses the Playwright Chromium cache). Optional env: `Y=<offset>` to crop from a vertical offset, `EVAL=<js>` to run a snippet first, for example to click buttons. Diponty is a layout reference only: use its structure, never its logo, text or photos.

## Known notes

- `/saree` Load More asks for `12 x page` products at once. The storefront fetches them in pages of up to the API limit of 50, so larger counts still arrive in full.
- Next 16 returns HTTP 200 for `notFound()` once streaming starts (soft 404); product pages carry `noindex` as mitigation.
- Claude may run tests, lint and builds and push feature branches (owner said yes 2026-10-07); dev servers, seed scripts and `master` stay with the owner (see root `CLAUDE.md`).

## Manual resume commands

```bash
cd /d/Work/COOVI/coovi-api && pnpm dev
cd /d/Work/COOVI/coovi-storefront && pnpm dev
cd /d/Work/COOVI/coovi-admin && pnpm dev
curl http://localhost:5000/api/products
```

Quick health check once running: `curl http://localhost:5000/api/orders/delivery-fee` should return `success: true` with `deliveryFee`, `zones` and `districts`.
