# Admin Feature Plan

Written 2026-10-12. Implementation plan for the 18 admin features needed to run Coovi as a real online shop. Nothing in this file is built yet. Current state and backlog live in `QUICK_STATUS.md`; the API contract lives in `API_ENDPOINTS.md`.

## How to read this file

Each feature has the same parts:

- **Goal**: what the owner can do afterwards.
- **API**: changes in `coovi-api` (models, routes, env).
- **Admin**: changes in `coovi-admin` (pages, components, types).
- **Storefront**: changes in `coovi-storefront`, or "none".
- **Tests**: what to cover.
- **Size**: S (one evening), M (two to three evenings), L (a week of evenings or more).
- **Depends on**: features or groundwork that must be done first.

## Rules for every feature

1. **API first.** Build and merge the API change, then the admin, then the storefront. New request fields are optional with a safe default, so the live storefront keeps working between deploys.
2. **One branch and one pull request per repo per feature.** Branch name `feature/<short-name>`. The owner merges.
3. **Update `API_ENDPOINTS.md`** in the same piece of work as any route or field change.
4. **The API stays the source of truth** for prices, stock, fees, totals and status. The admin and storefront only send choices (IDs, quantities, area, coupon code), never amounts.
5. **Tests with every change**: vitest in all three repos; run typecheck, lint and tests before the pull request.
6. **Old documents must still load.** Every new Mongoose field is optional or has a default, so the 26 products and existing orders need no manual migration.

## Build order

| Phase | Features | Why this order |
|---|---|---|
| 0 | Groundwork G1 to G3 | Small refactors that features 2, 3, 14, 15 and 17 all reuse. |
| 1 | 1, 2, 3, 4 | The daily order flow. Without these a COD shop cannot be run. |
| 2 | 6, 5 | Settings page first, then delivery areas stored in it. |
| 3 | 12, 11, 8 | Search, reports and customers: needed once orders pile up. |
| 4 | 7, 10, 14 | Categories, discount codes, manual orders. |
| 5 | 13, 15, 17, 16 | Staff accounts, bulk actions, stock log, banners. |
| 6 | 9, 18 | Variants and reviews: largest, least urgent. |

---

## Phase 0: groundwork

### G1. Move order logic out of the route file

`coovi-api/src/routes/orders.ts` holds pricing, status transitions and stock changes inline. Later features need the same logic from more than one route.

- Create `src/services/orderPricing.ts`: `buildOrderItems(items)` (loads products, checks `inStock` and `stock`, returns items and subtotal). Moved from `POST /api/orders` unchanged.
- Create `src/services/orderStatus.ts`: `changeOrderStatus(orderId, newStatus, options)` with the atomic claim, stock take, rollback and stock return. Move `NEXT_STATUSES` here and re-export it from the route so tests keep importing it.
- Create `src/services/stock.ts`: `adjustStock(productId, change, reason)`. Every stock change goes through it. Feature 17 later adds logging inside this one function.
- No behaviour change. The existing 84 tests must pass untouched; that is the proof the refactor is safe.

Size: S.

### G2. Public and admin views of an order

`GET /api/orders/:orderNumber` (public tracking) returns the whole order document. Features 3, 8 and 11 add fields customers must not see (internal notes, cost price, who changed a status).

- Add a `PUBLIC_ORDER_FIELDS` select list in `orders.ts` and use it in the public `GET /:orderNumber` and the `POST /` response.
- Add a test that fails if a new private field leaks into the public response.

Size: S.

### G3. Who did it

`req.admin` already carries `id`, `email` and `role` from the JWT (`src/middleware/auth.ts`). Add a small helper `actor(req)` returning `{ id, email }` to stamp on notes, status history and stock movements.

Size: S.

---

## Phase 1: daily order flow

### 1. New-order alerts

**Goal**: the owner's phone buzzes when an order arrives, and the admin shows how many orders are waiting.

**API**
- New `src/services/notify.ts` with `notifyNewOrder(order)`. Two channels, each switched on only when its env values are set (same pattern as Cloudinary):
  - **Telegram bot** (recommended first): one HTTPS call to the Bot API with `TELEGRAM_BOT_TOKEN` and `TELEGRAM_CHAT_ID`. Free, instant, no approval needed.
  - **Email** through an HTTP email API such as Resend or Brevo: `EMAIL_API_KEY`, `NOTIFY_EMAIL_TO`. Use an HTTP API, not SMTP, because Render's free plan blocks outgoing SMTP ports (confirm on Render's docs before building).
- Call it from `POST /api/orders` **after** the response is sent, without `await`, inside `try/catch`. A failed alert must never fail or slow an order.
- Message content: order number, customer name, phone, total, item count, link to the admin order.
- `src/config/env.ts`: warn when no channel is configured.
- `.env.example`: add the new keys with empty values.
- WhatsApp alerts need the paid WhatsApp Business API and an approved template; leave for later.

**Admin**
- `DashboardLayout.tsx`: badge on the Orders menu item with the Pending count. React Query with `refetchInterval: 60_000` on `GET /orders?status=Pending&limit=1`, reading `pagination.total`.
- Optional: browser tab title `(3) Coovi Admin` and a sound when the count goes up.

**Storefront**: none.

**Tests**: `notify.ts` with `fetch` mocked (sends when configured, silent when not, swallows errors); order creation still returns 201 when the notifier throws.

**Size**: S. **Depends on**: nothing.

### 2. Cancel and return with automatic restock

**Goal**: mark a refused or returned parcel, record why, and get the stock back without editing the product by hand.

Today a `Shipped` order can only become `Delivered`. A parcel refused at the door has no status, and its stock is lost.

**API**
- `Order.status` enum: add `Returned`.
- New transitions in `NEXT_STATUSES`: `Shipped: ['Delivered', 'Returned']`, `Delivered: ['Returned']`, `Returned: []`.
- `PATCH /api/orders/:id/status` body gains optional `reason` (string, max 300) and `restock` (boolean, default `true`).
  - `reason` is required when the new status is `Cancelled` or `Returned`.
  - `Shipped -> Returned`: stock goes back (the parcel came back unopened).
  - `Delivered -> Returned`: stock goes back only when `restock` is true, because the item may be damaged.
- New order fields: `cancelReason?: string`, `returnedAt?: Date`.
- `FINAL_STATUSES` (frozen details): add `Returned`.
- Fixed reason list offered by the admin, stored as text: customer refused, customer unreachable, wrong address, changed mind, damaged, out of stock, duplicate order, other.

**Admin**
- `types/index.ts` and `utils/orderStatus.ts`: add `Returned` (chip colour `secondary`) and the new transitions.
- `OrderDetailModal.tsx`: choosing Cancelled or Returned opens a small dialog with a reason dropdown, optional free text, and a "Put stock back" checkbox for `Delivered -> Returned`.
- `utils/dashboardStats.ts`: revenue counts `Delivered` only and excludes `Returned`; add a "Returned" count card.
- `utils/orderExport.ts`: add a Reason column.

**Storefront**: the track-order page must show `Returned` with suitable wording. Check where it maps status to text and colour.

**Tests**: each new transition; stock restored on `Shipped -> Returned`; `restock: false` leaves stock alone; reason required; double click cannot restock twice (existing atomic claim).

**Size**: M. **Depends on**: G1.

### 3. Internal notes and status history

**Goal**: write "called, no answer" on an order, and see who changed its status and when.

**API**
- New order fields:
  - `internalNotes: [{ text, by, at }]`
  - `statusHistory: [{ from, to, by, at, reason? }]`
- `POST /api/orders/:id/notes` (admin): body `{ text }` (1 to 500 characters); appends with `$push`. Notes are append-only; no edit or delete, so the record can be trusted.
- `changeOrderStatus` pushes a history entry in the **same** `findOneAndUpdate` that claims the transition (`$set` status plus `$push` statusHistory). The stock-rollback path must also remove that entry.
- `POST /api/orders` writes the first entry (`to: 'Pending'`, `by: 'customer'`).
- Both fields are excluded from the public tracking response (G2). The customer's own `notes` field stays as it is.

**Admin**
- `OrderDetailModal.tsx`: a "Timeline" section mixing notes and status changes, newest first, plus a text box with an "Add note" button.
- `api/orders.ts`: `addNote(id, text)`; invalidate the orders query on success.
- Orders table: a small note icon on rows that have notes.

**Storefront**: none.

**Tests**: note added with the right author; empty or oversized note rejected; history entry on every transition; history rolled back when stock is insufficient; public endpoint returns neither field.

**Size**: M. **Depends on**: G1, G2, G3.

### 4. Courier details

**Goal**: record which courier took the parcel and its tracking number, and show it to the customer.

**API**
- New order field: `courier?: { name, trackingNumber, bookedAt }`.
- `PATCH /api/orders/:id/status`: optional `courier` object accepted when the new status is `Shipped`.
- `PATCH /api/orders/:id`: add `courier` to `orderDetailsSchema` so it can be corrected while the order is not final.
- Courier name is free text validated to 50 characters; the admin offers Pathao, Steadfast, RedX, Sundarban, Other.
- `courier.name` and `courier.trackingNumber` are public (added to `PUBLIC_ORDER_FIELDS`).
- Later, not now: automatic booking through the Steadfast or Pathao merchant API, which would fill these fields without typing.

**Admin**
- Moving to Shipped opens a dialog asking for courier and tracking number (both optional, so a hand delivery still works).
- Order dialog shows the courier block with a copy button for the tracking number.
- Print slip and CSV export include courier and tracking number.

**Storefront**: track-order page shows "Sent with Pathao, tracking number X".

**Tests**: courier saved with the Shipped transition; editable while Shipped; frozen after Delivered; visible on the public endpoint.

**Size**: S. **Depends on**: nothing (G2 if done after feature 3).

---

## Phase 2: settings and delivery

### 6. Shop settings page

**Goal**: change the WhatsApp number, delivery fees and announcement text from the admin, with no code change or redeploy.

Built before feature 5 because the delivery fees are stored here.

**API**
- New model `src/models/Settings.ts`: a single document (`key: 'shop'`, unique) with:
  - `whatsappNumber`, `supportPhone`
  - `announcementText`, `announcementActive`
  - `deliveryFees: { insideDhaka, outsideDhaka }`
  - `lowStockThreshold`
- `src/services/settings.ts`: `getSettings()` creates the document on first read, using `DELIVERY_FEE` from env as the starting fee. Cache in memory for 60 seconds so every checkout is not a database read.
- `GET /api/settings` (public, `readLimiter`): public fields only.
- `PUT /api/settings` (admin): `z.strictObject` validation; clears the cache.
- `getDeliveryFee()` in `orders.ts` reads from settings. `DELIVERY_FEE` in env stays only as the first-run default.

**Admin**
- New `pages/SettingsPage.tsx`, route `/settings`, menu item in `DashboardLayout.tsx`.
- Sections: Contact, Announcement, Delivery fees, Stock alerts. One Save button per section.
- `api/settings.ts` plus a `Settings` type.

**Storefront**
- `lib/site.ts` holds the WhatsApp number today. Replace it with a server fetch of `/api/settings` (revalidate every 60 seconds), keeping the current value as the fallback when the API is unreachable.
- Announcement strip reads its text and on/off state from settings. Layout unchanged.

**Tests**: first read creates defaults; public response hides private fields; PUT rejects unknown fields and negative fees; cache cleared after PUT.

**Size**: M. **Depends on**: nothing.

### 5. Delivery fee by area

**Goal**: charge one fee inside Dhaka and another outside.

**API**
- `orderBodySchema`: add `deliveryArea: 'inside_dhaka' | 'outside_dhaka'`, optional, default `inside_dhaka` so the currently deployed storefront keeps working.
- Fee looked up from `settings.deliveryFees` by area. The client sends the area, never the amount.
- New order field `deliveryArea`.
- `GET /api/orders/delivery-fee`: keep the existing `deliveryFee` field (the inside-Dhaka fee) and add `zones: { inside_dhaka, outside_dhaka }`.
- `PATCH /api/orders/:id`: admin may change `deliveryArea` while the order is still `Pending`; the API recomputes `deliveryFee` and `total`.

**Admin**
- Order dialog and print slip show the area. Area filter on the Orders page. CSV column.

**Storefront**
- Checkout: a two-option area choice above the order summary; the summary updates the fee and total from `zones`. This adds a form control to checkout, so show the owner a screenshot at 375 and 1440 before merging.
- `/delivery-policy` shows both fees.

**Tests**: each area charges its fee; missing area defaults; invalid area rejected; a client-sent fee is ignored; admin area change recomputes the total and is refused after Pending.

**Size**: M. **Depends on**: 6.

---

## Phase 3: once orders pile up

### 12. Real pagination and search on orders

**Goal**: find any order by number, phone or name; the page stays fast with thousands of orders.

Today `ordersApi.getAll()` downloads every order (`fetchAllPages`, 100 per page) and the admin filters, counts and charts in the browser.

**API**
- `GET /api/orders` gains `search` (order number, phone or customer name, regex-escaped like the products route), `from`, `to` (dates), `sort`.
- `orderNumber` and `phone` are already indexed; add a compound index `{ status: 1, createdAt: -1 }` for the filtered list.
- New `GET /api/orders/stats` (admin): counts per status, today's orders and revenue. The dashboard and the menu badge use this instead of downloading all orders.

**Admin**
- `OrdersPage.tsx`: server-side pagination (MUI `TablePagination` or DataGrid server mode), debounced search box, date range. React Query key includes page and filters, with `placeholderData: keepPreviousData`.
- `utils/orderFilters.ts` shrinks to building query parameters.
- CSV export keeps using `fetchAllPages`, but with the current filters passed to the API.
- `DashboardPage.tsx` moves to `/orders/stats` (and to the reports endpoint from feature 11 for the chart).

**Storefront**: none.

**Tests**: search by each field; special characters in search do not error; date range; stats totals match a known data set.

**Size**: M. **Depends on**: nothing; do it together with 11.

### 11. Reports

**Goal**: see best sellers, sales for any date range, return rate and profit.

**API**
- `Product.costPrice?: number` (what the owner paid). **Private**: public `GET /api/products` and `GET /api/products/:slug` must exclude it. Add `GET /api/products/admin/:id` (admin) that returns it, registered before `/:slug`.
- Order items snapshot `costPrice` at order time, so later cost changes do not rewrite old profit. Excluded from the public order view (G2).
- New `src/routes/reports.ts`, `GET /api/reports/summary?from=&to=` (admin), built with MongoDB aggregation:
  - revenue, order count and average order value per day (Delivered only)
  - best sellers by quantity and by revenue (top 10)
  - status breakdown and return rate (`Returned / (Delivered + Returned)`)
  - profit (`sum of (price - costPrice) x quantity`), counted only for items that have a cost
- Days are grouped in the `Asia/Dhaka` timezone, not UTC.

**Admin**
- New `pages/ReportsPage.tsx`, route `/reports`: date range picker (Today, 7 days, 30 days, This month, Custom), summary cards, the existing `RevenueChart.tsx` fed from the API, best-sellers table.
- `ProductFormPage.tsx`: "Cost price" field with the profit margin shown beside it.

**Storefront**: none (confirm `costPrice` never appears in a product response).

**Tests**: aggregation against a fixed set of orders; timezone boundary (an order at 11:30 pm Dhaka time counts for that day); `costPrice` absent from public endpoints.

**Size**: L. **Depends on**: 2 (for the Returned status), G2.

### 8. Customers list

**Goal**: see repeat buyers, and spot phone numbers that keep refusing parcels before shipping to them again.

Checkout is guest-only, so a "customer" is a phone number.

**API**
- No customer collection. `GET /api/customers` (admin) aggregates orders grouped by `phone`: latest name and address, order count, delivered, cancelled, returned, total spent, last order date. Supports `search`, `page`, `limit`, `sort`.
- `GET /api/customers/:phone` (admin): that phone's orders.
- New model `CustomerFlag { phone (unique), blocked, note, by, at }` with `PUT /api/customers/:phone/flag`.
- `POST /api/orders`: a blocked phone gets a 403 asking the customer to contact the shop on WhatsApp. Keep the wording polite.
- `GET /api/orders` (admin list) adds a per-order `customerStats` summary, or the order dialog fetches `/customers/:phone` on open (simpler; choose this).

**Admin**
- New `pages/CustomersPage.tsx`, route `/customers`: table with search, a "risky" chip when returned plus cancelled is two or more, click through to that customer's orders.
- `OrderDetailModal.tsx`: a line such as "4 earlier orders: 2 delivered, 2 returned" with a warning colour when risky. This is the main payoff of the feature.
- Block and unblock button with a note.

**Storefront**: checkout shows the API's blocked message (it already shows API error messages; verify).

**Tests**: aggregation counts; blocked phone refused; unblocked phone accepted; phone search.

**Size**: M. **Depends on**: 2.

---

## Phase 4: growing the catalogue and sales

### 7. Categories

**Goal**: group products (Cotton, Silk, Jamdani and so on) and let customers browse by group.

**API**
- New model `Category { name, slug (unique), sortOrder, active }`.
- `GET /api/categories` (public, active only, sorted), `POST`, `PUT /:id`, `DELETE /:id` (admin).
- `Product.category` stays a string holding the category **slug**. On startup, create a `saree` category if none exists and convert existing `'Saree'` values, the same way the first admin is seeded in `src/index.ts`.
- Product create and update reject a category that does not exist.
- Deleting a category that still has products returns 409 with the product count.
- `GET /api/products?category=<slug>` already works.

**Admin**
- New `pages/CategoriesPage.tsx`: list, add, rename, reorder, hide.
- `ProductFormPage.tsx`: category becomes a dropdown. `ProductsPage.tsx`: category filter (`utils/productFilters.ts`).

**Storefront**
- New `/category/[slug]` page reusing the `/shop` grid, plus sitemap and `llms.txt` entries.
- Category links in the header menu. This changes navigation, so get the owner's approval on placement first.

**Tests**: CRUD; duplicate slug; delete blocked while in use; product with an unknown category rejected; startup conversion runs once.

**Size**: M. **Depends on**: nothing.

### 10. Discount codes

**Goal**: create a code such as `EID10` for a campaign or to make up for a mistake.

**API**
- New model `Coupon { code (unique, uppercase), type: 'percent' | 'fixed', value, minSubtotal, maxUses, usedCount, startsAt, expiresAt, active }`.
- Admin CRUD at `/api/coupons`.
- `POST /api/coupons/validate` (public, rate-limited): body `{ code, items }`; returns the discount amount or a clear reason (expired, minimum not reached, used up). Uses `buildOrderItems` so the subtotal is the server's.
- `orderBodySchema`: optional `couponCode`. The API recomputes the discount; `total = subtotal - discount + deliveryFee`. A percent discount is rounded to whole taka and can never exceed the subtotal.
- Use count is claimed atomically: `updateOne({ code, usedCount: { $lt: maxUses } }, { $inc: { usedCount: 1 } })`, the same pattern as stock. Cancelling an order gives the use back.
- New order fields: `couponCode?`, `discount` (default 0).

**Admin**
- New `pages/CouponsPage.tsx`: list with uses and status, create and edit dialog, on/off switch.
- Order dialog, print slip and CSV show the discount line.

**Storefront**
- Checkout: "Have a code?" field calling validate, showing the discount in the summary. The final amount still comes from the order response.

**Tests**: percent and fixed; minimum subtotal; expiry; use limit under two simultaneous orders; invalid code leaves the order unaffected (decide: reject the order, do not silently ignore); a client-sent discount is ignored.

**Size**: L. **Depends on**: G1.

### 14. Manual order entry

**Goal**: enter an order taken by Facebook, WhatsApp or phone so stock and reports stay correct.

**API**
- `POST /api/orders/manual` (admin): same body as the public order plus `source: 'facebook' | 'whatsapp' | 'phone' | 'other'` and optional `deliveryFeeOverride` and `discount` (an admin is trusted to agree a price by phone). Uses `buildOrderItems`, so prices still come from the database.
- New order field `source` (default `'website'`) and `createdBy`.
- Not rate-limited like the public route, and skips the blocked-phone check with a warning in the response.

**Admin**
- New `pages/OrderFormPage.tsx`, route `/orders/new`: product search with quantity, customer fields, area, source, live total preview.
- If feature 8 is built: typing a phone number fills in the last name and address.
- Source column and filter on the Orders page; source breakdown in reports.

**Storefront**: none.

**Tests**: admin-only; prices from the database; stock checked; override and discount applied; source saved.

**Size**: M. **Depends on**: G1; better after 5 and 8.

---

## Phase 5: scaling the team and the workload

### 13. Second admin account and roles

**Goal**: give a helper a login that can process orders but cannot see revenue, change settings or delete products.

**API**
- `Admin.role`: `'owner' | 'staff'`, plus `active: boolean`. On startup convert the existing `'admin'` role to `'owner'`.
- `requireAdmin` accepts both roles and loads the admin from the database to check `active`, so a removed helper loses access at once instead of when the one-day token expires.
- New `requireOwner` middleware for: admin management, `PUT /settings`, reports, coupons, product delete, customer blocking.
- `GET /api/admins`, `POST /api/admins` (owner sets a temporary password), `PATCH /api/admins/:id` (role, active), `POST /api/admins/:id/reset-password`. The last owner cannot be demoted or deactivated.
- Tokens already signed with `role: 'admin'` stop working after deploy; the owner signs in again once. Note this in the pull request.

**Admin**
- New `pages/TeamPage.tsx`, route `/team` (owner only).
- `DashboardLayout.tsx` hides owner-only menu items for staff; `utils/auth.ts` exposes the role from the token. The API is still what enforces it.
- Staff dashboard shows order counts but no revenue.

**Storefront**: none.

**Tests**: staff refused on each owner route (403); deactivated admin refused with a valid token; last owner protected; old `'admin'` role converted.

**Size**: M. **Depends on**: G3; do after 6 and 11 so their routes get the owner guard in one pass.

### 15. Bulk actions

**Goal**: mark ten orders shipped or print ten slips in one go.

**API**
- `POST /api/orders/bulk-status` (admin): `{ ids (max 50), status, courier?, reason? }`. Loops over `changeOrderStatus` and returns a result per order (`ok` or the error message), so one failure does not hide nine successes.
- `PATCH /api/products/bulk` (admin): `{ ids, changes: { inStock?, category?, priceChangePercent? } }`.

**Admin**
- Checkbox selection on the Orders and Products tables; an action bar appears when rows are selected.
- Bulk print: render the existing slip once per selected order with a CSS page break between them.
- A results dialog listing any orders that could not be changed and why.

**Storefront**: none.

**Tests**: mixed success and failure; limit of 50; stock correct after a bulk confirm where one order lacks stock.

**Size**: M. **Depends on**: G1, 12.

### 17. Stock history log

**Goal**: when the shelf and the screen disagree, see every change that led to the number.

**API**
- New model `StockMovement { productId, change, stockAfter, reason: 'order' | 'cancel' | 'return' | 'manual' | 'initial', orderNumber?, by, at }`, indexed on `{ productId: 1, at: -1 }`.
- Written inside `adjustStock` (G1), so order confirm, cancel and return are logged with no extra code in the routes.
- `PUT /api/products/:id`: when `stock` differs from the stored value, log a `manual` movement. Optional `stockNote` in the body.
- `GET /api/products/:id/stock-history` (admin), paginated.

**Admin**
- `ProductFormPage.tsx`: a "Stock history" panel showing date, change, resulting stock, reason, linked order and who.

**Storefront**: none.

**Tests**: one movement per stock change on each path; nothing logged when a product is saved with unchanged stock; rollback on insufficient stock logs a matching reversal or nothing (pick one and test it).

**Size**: S. **Depends on**: G1, G3.

### 16. Homepage banner from the admin

**Goal**: swap the hero image and text for a sale without touching code.

**API**
- New model `Banner { image, heading, subheading, buttonText, linkUrl, sortOrder, active, startsAt?, endsAt? }`.
- `GET /api/banners` (public, active and in date), admin CRUD.
- `POST /api/uploads/signature` signs for the `coovi/products` folder today; allow a `coovi/banners` folder too.

**Admin**
- New `pages/BannersPage.tsx`: list with preview, form reusing the product photo upload button, reorder, on/off switch.

**Storefront**
- The hero reads the first active banner and falls back to the current built-in hero when there are none or the API is down. Same size, position and structure as today; only the content becomes dynamic.

**Tests**: date window filtering; inactive hidden; storefront fallback when the list is empty.

**Size**: M. **Depends on**: nothing.

---

## Phase 6: largest and least urgent

### 9. Product attributes and variants

**Goal**: describe a saree properly (colour, fabric, work, length) and, if needed, sell one design in several colours with separate stock.

Split in two, because the first half is cheap and the second is the biggest change in this file.

**9a. Attributes (S)**
- `Product.attributes?: { color, fabric, work, length, blouse }`, all optional strings.
- Admin form section; storefront product page shows a details table and adds them to the Product structured data.

**9b. Variants (L)**: build only if the shop really stocks the same design in several colours.
- `Product.variants: [{ _id, label, stock, images? }]`. A product with no variants behaves exactly as today.
- Order items gain `variantId` and `variantLabel`; `orderBodySchema` items gain optional `variantId`, required when the product has variants.
- Stock checks and `adjustStock` work on the variant (`arrayFilters`), and the product's `stock` becomes the sum of its variants.
- Admin form: variants table. Storefront: colour picker on the product page; the cart key becomes product plus variant.
- Touches checkout, cart, order dialog, print slip, CSV, low-stock list and reports, so plan it as its own small project with a written test list first.

**Depends on**: G1, 17 (so variant stock is logged from the start).

### 18. Reviews and back-in-stock requests

**Goal**: show real customer reviews after approval, and know who is waiting for a sold-out saree.

**Reviews (M)**
- Model `Review { productId, orderNumber, name, rating (1 to 5), text, status: 'pending' | 'approved' | 'rejected' }`.
- `POST /api/reviews` (public, rate-limited): accepted only when the order number and phone match a `Delivered` order containing that product, one review per order item. This stops fake reviews without customer accounts.
- `GET /api/products/:slug/reviews` (public, approved only); admin list and approve or reject.
- Admin `pages/ReviewsPage.tsx` with a pending queue and a badge.
- Storefront: review list and average on the product page, `aggregateRating` in the structured data, and a "Write a review" link on the tracking page for delivered orders.

**Back-in-stock (S)**
- Model `StockRequest { productId, phone, createdAt, notifiedAt? }`; `POST /api/products/:id/notify-me` (public, rate-limited, one per phone per product).
- Admin: a "Waiting" count on the product row, the phone list on the product form, and a button that marks them as notified. The owner messages them on WhatsApp by hand at first.
- Storefront: a "Tell me when it is back" phone field on sold-out products.

**Depends on**: 2 for reviews (only Delivered orders qualify).

---

## Summary table

| # | Feature | Size | Repos touched | Depends on |
|---|---|---|---|---|
| G1 | Order logic into services | S | api | none |
| G2 | Public order view | S | api | none |
| G3 | Actor helper | S | api | none |
| 1 | New-order alerts | S | api, admin | none |
| 2 | Cancel and return with restock | M | api, admin, storefront | G1 |
| 3 | Internal notes and history | M | api, admin | G1, G2, G3 |
| 4 | Courier details | S | api, admin, storefront | none |
| 6 | Shop settings page | M | api, admin, storefront | none |
| 5 | Delivery fee by area | M | api, admin, storefront | 6 |
| 12 | Orders pagination and search | M | api, admin | none |
| 11 | Reports | L | api, admin | 2, G2 |
| 8 | Customers list | M | api, admin | 2 |
| 7 | Categories | M | api, admin, storefront | none |
| 10 | Discount codes | L | api, admin, storefront | G1 |
| 14 | Manual order entry | M | api, admin | G1 |
| 13 | Second admin and roles | M | api, admin | G3 |
| 15 | Bulk actions | M | api, admin | G1, 12 |
| 17 | Stock history log | S | api, admin | G1, G3 |
| 16 | Homepage banner | M | api, admin, storefront | none |
| 9a | Product attributes | S | api, admin, storefront | none |
| 9b | Product variants | L | api, admin, storefront | G1, 17 |
| 18 | Reviews and back-in-stock | M | api, admin, storefront | 2 |

## Open questions for the owner

1. **Alerts**: Telegram, email, or both? Telegram is the quickest to set up.
2. **Returns**: is a return after delivery something the shop accepts? If not, drop `Delivered -> Returned`. This also decides the wording on `/return-policy`.
3. **Delivery areas**: are two zones enough, or is a third (Dhaka suburbs) needed? Which couriers will be used?
4. **Blocked customers**: refuse the order outright, or accept it and flag it for a confirmation call?
5. **Variants**: does the shop stock the same design in several colours, or is each saree one of a kind? This decides whether 9b is ever needed.
6. **Staff**: will anyone else use the admin in the next few months? If not, 13 can move to the end.
