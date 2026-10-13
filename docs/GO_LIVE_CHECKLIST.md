# Needed before going live

What has to change before Coovi takes real orders from real customers. Written 2026-10-13 from a read of the code in all three repos and of `QUICK_STATUS.md`; update it as items are done.

## How to read this file

- **Priority 1**: fix before taking real orders. Each one can lose an order, lose data, or leak a customer's details.
- **Priority 2**: fix in the first weeks after launch, before orders become frequent.
- **Priority 3**: worth doing as the shop grows.
- **Who**: **You** means it needs your own accounts, money, credentials or business decisions; Claude cannot do it. **Claude** means Claude can build it in a pull request for you to review and merge. **Both** means you decide or sign up first, then Claude builds.

What is already in good shape (no action needed): prices, totals and the delivery fee are computed by the API, never trusted from the browser; order status only moves forward and stock changes are safe when two admins click at once; the API refuses to start in production with a weak secret, weak admin password or localhost CORS; login, checkout and order lookup are rate limited; all three repos have CI with tests.

## Priority 1: before taking real orders

| # | Item | Why it matters | Who |
|---|---|---|---|
| 1 | **Separate production database.** Create the `coovi-prod` database and user (steps in `QUICK_STATUS.md`, "Waiting on you" item 4) and point Render's `MONGODB_URI` at it. | The live site uses the dev database today, so test orders, demo products and real customer data are mixed, and anything run against dev (see item 2) hits the live shop. | You |
| 2 | **Guard the seed script.** `pnpm seed` deletes every product (`coovi-api/src/seed.ts` line 83) with no check of which database it is connected to. | While the live site uses the dev database, one `pnpm seed` on your laptop wipes the live catalogue. Make it refuse to run against a production database or without an explicit confirmation flag. | Claude |
| 3 | **Backups.** The free Atlas cluster (M0) has no automatic backups. Either move to a paid Atlas tier with daily snapshots, or have Claude add a nightly `mongodump` job (GitHub Actions) that stores a copy somewhere private. | Without a backup, one mistake or one bad deploy can lose every order and customer record for good. | Both: you choose paid tier or nightly job and create the storage account; Claude builds the job |
| 4 | **API that stays awake.** Render's free plan puts the API to sleep after about 15 minutes without visitors and takes up to a minute to wake. The storefront gives up after 8 seconds (`TIMEOUT_MS` in `coovi-storefront/lib/api.ts`). | The first visitor after a quiet spell sees an error page instead of sarees. Moving the API to Render's paid Starter plan (about 7 USD a month) fixes it; pinging `/health` every few minutes is a free workaround that keeps it mostly awake. | You (plan and payment) |
| 5 | **Storefront shares one rate limit.** Product pages and the order-confirmation page load their data on Vercel's servers, so the API sees Vercel's few IP addresses instead of each shopper. The read limit is 100 requests a minute per address and order lookups 20 a minute (`coovi-api/src/middleware/rateLimiters.ts`), and the storefront caches nothing. | With a handful of shoppers at once the API starts answering "Too many requests" for everyone, including customers trying to see their order. Fix: cache product data in the storefront for about a minute, and let the storefront's server identify itself to the API with a secret header so it gets its own, higher limit. | Claude (you add one secret to Render and Vercel) |
| 6 | **New-order alerts.** Nothing tells you when an order arrives (backlog item 1; plan in `docs/ADMIN_FEATURE_PLAN.md`, feature 1). | Cash-on-delivery customers expect a call within hours. An order you notice tomorrow is often a lost order. | Both: you pick email, SMS or WhatsApp and create the account; Claude builds |
| 7 | **Fixed in coovi-api PR #12 (merged 2026-10-13).** **Order lookup accepts a list of phones.** `GET /orders/:orderNumber?phone=a&phone=b` is turned into "phone is a or b" by Mongoose (checked 2026-10-13), and order numbers are only 3 random digits per day (`ORD-YYYYMMDD-NNN`, 1,000 possibilities). | The order number plus phone is the only thing protecting a customer's name and address. Accept exactly one phone, and make order numbers much harder to guess (for example 6 random characters). | Claude |
| 8 | **Hosting terms for a business.** Vercel's free Hobby plan is for personal, non-commercial use; a shop selling sarees is commercial. | Vercel can suspend a commercial site on Hobby. Move the storefront and admin to Vercel Pro (paid) or another host that allows commercial use. | You |
| 9 | **Real domain.** The shop lives at `coovi-storefront.vercel.app`. Buy a domain (for example `coovi.com.bd` or `coovi.shop`), connect it to Vercel and Render, then update `NEXT_PUBLIC_SITE_URL` and `CORS_ORIGINS`. | Customers trust a real address more, and search engines, share links and the sitemap should use the address you will keep. Changing it later loses search ranking. | Both: you buy and connect it; Claude updates the config and checks the redirects |
| 10 | **Production secrets and admin.** New `JWT_SECRET`, production admin email and strong password, saved in a password manager (`QUICK_STATUS.md` item 4). | The dev admin password has been typed on laptops and in chats during development. | You |
| 11 | **Business details and placeholders.** Real WhatsApp number (placeholder `8801700000000`), delivery fee, real photos, policy wording with your return window, refund method and delivery times, and removal of the demo product and orders. | Customers will message the placeholder number and read promises the shop cannot keep. | You (tell Claude the values; Claude updates the code) |
| 12 | **Legal registration.** Check what Bangladesh requires of an online shop (trade licence, e-commerce registration under the Digital Commerce guidelines, how prices, delivery times and refunds must be shown) with an accountant or lawyer. Inferred from general knowledge, not checked against the current rules. | Unregistered online sellers can be fined or delisted by payment and courier partners. | You |

## Priority 2: first weeks after launch

| # | Item | Why it matters | Who |
|---|---|---|---|
| 13 | **Error tracking.** The API only prints errors to Render's log, which you never see unless you look. Add a free error tracker (for example Sentry) to the API, storefront and admin. | A broken checkout is silent today: you only find out when a customer complains, or never. | Both: you create the free account; Claude wires it in |
| 14 | **Uptime alert.** A free monitor (for example UptimeRobot or Better Stack) that checks `https://<api>/health` every few minutes and messages you when it fails. | You learn the shop is down before customers do. | You (5 minutes to set up; Claude can write the steps) |
| 15 | **Fake cash-on-delivery orders.** Anyone can place 20 orders an hour from one address with any phone number. | Fake orders waste courier fees and block stock. Start with a "call to confirm before shipping" habit (already natural with Pending → Processing); add phone verification by SMS code later if fakes appear. | Both: you decide; Claude builds verification if needed |
| 16 | **Stock is only taken when you confirm an order.** Two customers can both order the last piece; the second confirmation then fails with "insufficient stock". | Sarees are often one of a kind, so this will happen. Decide: reserve stock when the order is placed (the customer sees "sold out" at once) or keep today's rule and call the second customer. | Both: you decide; Claude builds |
| 17 | **Delivery fee by area.** One flat fee everywhere today (backlog item 3, plan feature 5). | Outside-Dhaka delivery usually costs more; a flat fee either loses money or overcharges Dhaka customers. | Both |
| 18 | **Admin sign-in strength.** One shared admin account, no two-step login, a sign-in stays valid for 1 day even after the password is changed, and the token sits in browser storage. | Whoever gets the admin password or a logged-in laptop can see every customer's address. Add sign-out-everywhere on password change first; two-step login and per-person accounts (plan feature 13) later. | Claude |
| 19 | **Customer data handling.** The orders CSV export puts every name, phone and address on your laptop; Atlas network access is probably open to every address (Render's free plan has no fixed IP). | A lost laptop or a leaked database password exposes customers. Keep exports in an encrypted folder and delete old ones, use a long Atlas password for the production user, and decide how long to keep old orders. | You |
| 20 | **Fixed in coovi-api PR #12 (merged 2026-10-13).** **Order numbers use UTC dates.** Orders placed between midnight and 6 am Bangladesh time get the previous day's date. | Confusing when matching orders to days. Small fix with item 7. | Claude |
| 21 | **Hide the admin from search engines.** The admin site has no `noindex`. | The login page can show up in Google. | Claude |

## Priority 3: as the shop grows

| # | Item | Why it matters | Who |
|---|---|---|---|
| 22 | Courier integration (Pathao, Steadfast, RedX) and tracking numbers (plan feature 4). | Saves typing every parcel by hand and lets customers track deliveries. | Both |
| 23 | Real order pagination and search in the admin (plan feature 12). The admin downloads every order on every visit. | Slows down once there are thousands of orders. | Claude |
| 24 | Audit log of who changed what (plan G3 and feature 3). | Needed once more than one person manages orders. | Claude |
| 25 | Visitor analytics (Vercel Analytics or Google Analytics, with a cookie notice if required). | Tells you which sarees people look at and where they drop off. | Both |
| 26 | Security headers (Content Security Policy) on the storefront and admin. | Extra protection against script injection. | Claude |
| 27 | Online payment (bKash, Nagad, SSLCommerz) if you want prepaid orders. | Cuts fake orders and courier cash handling; needs a merchant account and careful payment code. | Both |
| 28 | Delete a product's photos from Cloudinary when the product is deleted. | Keeps the free Cloudinary storage from filling up. | Claude |

## Suggested first fixes

Claude can start these now, in this order, without waiting on any of your accounts:

1. Item 2: guard the seed script (small, removes the biggest accident risk today).
2. Item 7 and 20: one phone only on order lookup, harder-to-guess order numbers in Bangladesh time.
3. Item 5: storefront caching and its own rate limit.
4. Item 18: sign-out-everywhere when the admin password changes.

In parallel, the items marked **You** in Priority 1 (production database, backups decision, paid API plan, hosting terms, domain, secrets, business details, registration) unblock the rest.
