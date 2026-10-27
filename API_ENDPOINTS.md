# COOVI API Contract

Canonical contract shared by `coovi-api`, `coovi-storefront` and `coovi-admin`. Base URL (dev): `http://localhost:5000/api`.
Source of truth is the code in `coovi-api/src/routes/`; update this file in the same change as any route change.

## Conventions

- Every response is JSON: `{ "success": boolean, "data"?, "message"?, "errors"?, "pagination"? }`.
- Validation failures return `400` with `errors: ["field: reason", ...]`. Unknown routes return `404` JSON.
- Money is whole BDT (integers). Dates are ISO strings.
- Admin routes need `Authorization: Bearer <JWT>` (token from `POST /auth/login`, expires in 1 day). Missing or bad token returns `401`. Every admin request also checks the account in the database: a switched-off account, or a token signed before the account's last password change or password reset, returns `401` at once. Role and permissions are read on every request, so changes apply on the next request without signing out.
- Access: each admin route below names the permission it needs, for example **(orders.edit)**. Without it the API returns `403 You do not have access to this. Ask the shop owner.` Owners have every permission. Routes marked **(owner)** are for owners only and return `403 Only the shop owner can do this`. Routes marked (admin) only need a valid sign-in.
- Roles are `owner`, `manager`, `staff` and `viewer`. Each role except owner is a starting set of permissions that the owner can adjust per person. Permissions:

| Permission | Allows | Role presets |
|---|---|---|
| `orders.view` | `GET /orders` | manager, staff, viewer |
| `orders.edit` | `POST /orders/manual`, `PATCH /orders/:id`, `PATCH /orders/:id/status`, `PATCH /orders/:id/call-confirmed`, `POST /orders/:id/notes`, `POST /orders/:id/courier/steadfast`, `POST /orders/:id/courier/steadfast/refresh` | manager, staff |
| `orders.export` | the admin CSV export button (the data comes from `GET /orders`) | manager |
| `products.view` | the admin product list | manager, staff, viewer |
| `products.edit` | `POST /products`, `PUT /products/:id`, `POST /uploads/signature` | manager, staff |
| `products.delete` | `DELETE /products/:id` | manager |
| `money.view` | revenue on the admin dashboard | manager |
| `payments.view` | `GET /courier-payments*` | manager |
| `payments.edit` | `POST /courier-payments`, `DELETE /courier-payments/:id` | manager |
| `settings.view` | the admin Settings page | none |
| `settings.edit` | `PATCH /settings` | none |

Each Edit permission brings its View (`orders.edit`, `orders.export` and `money.view` bring `orders.view`; `products.edit` and `products.delete` bring `products.view`; `payments.edit` brings `payments.view`; `settings.edit` brings `settings.view`). The API adds them when saving.
- Rate limits (per IP): reads 100/min, login 5 per 15 min, order creation 5/hour, order lookup 20/min. Exceeding returns `429`.
- The storefront server identifies itself with header `x-coovi-storefront-key` (equal to `STOREFRONT_API_KEY`, server-only on both sides). With it, `x-coovi-client-ip` is used as the shopper's IP for the limits above; without a shopper IP it gets its own bucket (reads 1000/min, order lookup 200/min). Browsers never send these headers.
- CORS allows the origins in `CORS_ORIGINS` (default `http://localhost:3000`, `http://localhost:5173`).

## Authority rules

The API is the source of truth for prices, stock, delivery fee, order totals, order status and authorization. Clients send product IDs and quantities only. Unknown order fields (prices, totals) are ignored, never stored.

## Product object

| Field | Type | Notes |
|---|---|---|
| `_id` | string | Mongo ID |
| `slug` | string | unique, lowercase words joined by `-` |
| `name`, `nameBn?` | string | English / Bengali name |
| `description?`, `descriptionBn?` | string | up to 2000 chars |
| `price` | number | **current selling price**; what orders charge |
| `compareAtPrice?` | number | original price before a discount. The product is **on sale** when `compareAtPrice > price` |
| `images` | string[] | at least 1 `https://` URL |
| `shareImage?` | string | `https://` URL of a wide 1200x630 picture for social media link previews (the admin checks the size before upload). Without it the storefront uses the first photo |
| `size?` | string | |
| `category` | string | default `Saree` |
| `stock` | number | |
| `inStock` | boolean | |
| `allowPreorder` | boolean | default `false`. When on, the product can still be ordered when stock is short; the line becomes a pre-order |
| `preorderDays` | number | 1 to 90, default 15: the promised wait for a pre-order |
| `createdAt`, `updatedAt` | string | |

`costPrice` (what the shop paid for one piece) is stored on the product but left out of every product response; it is read with `GET /products/:id/cost`. When an order is placed the cost is copied onto each order line, so later cost changes don't rewrite old profit. That copy is never sent in any order response.

## Health

### `GET /health` (public)
Returns `200 { success: true, status: "ok", db: "connected", uptimeSeconds }`, or `503` with `status: "degraded"` when the database is not connected. Use it for uptime monitors and post-deploy smoke tests. `GET /` is a cheap liveness check that does not touch the database.

## Products

### `GET /products` (public)
Query (all optional; bad values fall back to defaults instead of erroring):

| Param | Default | Notes |
|---|---|---|
| `page` | 1 | min 1 |
| `limit` | 12 | 1 to 50 |
| `search` | none | partial, case-insensitive match on `name` |
| `sort` | `newest` | `newest`, `price-asc`, `price-desc`, `name-asc`, `name-desc` |
| `category` | none | exact match |
| `onSale` | `false` | `true` returns only products with `compareAtPrice > price` |

Response: `{ success, data: Product[], pagination: { page, limit, total, pages, hasMore } }`.

### `GET /products/:id/cost` (money.view)
Returns `{ data: { costPrice } }`, where `costPrice` is `null` when none is set, or `404`.

### `GET /products/:slug` (public)
Returns `{ success, data: Product }`, or `404` `Product not found`.

### `POST /products` (products.edit)
Body (strict, unknown fields rejected): `slug`, `name`, `price`, `images`, `stock` required; `nameBn`, `description`, `descriptionBn`, `shareImage`, `size`, `category` (default `Saree`), `inStock` (default `true`), `compareAtPrice`, `allowPreorder` (default `false`), `preorderDays` (whole number 1 to 90, default 15) optional.
`price` is a whole number of at least 1. `compareAtPrice` must be greater than `price`. Optional `costPrice` (0 or more) needs `money.view`, otherwise `403`. Returns `201 { data: Product }`; duplicate slug returns `400`.

### `PUT /products/:id` (products.edit)
Same body as create (full replacement of the listed fields). Optional fields left out (`nameBn`, `description`, `descriptionBn`, `shareImage`, `size`, `compareAtPrice`) are cleared. Send `compareAtPrice: null`, or leave it out, to remove a discount. The settings `category`, `inStock`, `allowPreorder` and `preorderDays` keep their saved value when left out (the create defaults are not applied on update). `costPrice` also keeps its saved value when left out; `null` removes it; sending it at all needs `money.view` (`403` otherwise). Returns `{ data: Product }`, `400` for invalid data or a duplicate slug, or `404`.

### `DELETE /products/:id` (products.delete)
Returns `{ success, message }` or `404`. The product's photos and share image are deleted from Cloudinary too (only photos in this shop's `coovi/products` folder). A photo still used by another product (as a photo or share image) or shown on an order line is kept, and a Cloudinary failure never stops the product being deleted.

## Orders

Order object: `_id`, `orderNumber` (`ORD-YYYYMMDD-XXXXXX`: the order's date in Bangladesh time, then 6 random characters from `23456789ABCDEFGHJKMNPQRSTVWXYZ`; orders placed before 2026-10-13 keep the older `ORD-YYYYMMDD-NNN`), `customerName`, `phone`, `address` (string), `district?` (one of the 64 districts; missing on orders placed before delivery areas), `deliveryArea` (`inside_dhaka` or `outside_dhaka`; older orders without it count as `inside_dhaka`), `items[]` (`productId`, `name`, `price`, `quantity`, `image`, `size?`, copied from the product at order time; `preorder` (boolean) and `preorderDays?` mark a line sourced for the customer), `subtotal`, `discount` (taka off the items, `0` unless an admin agreed one on a manual order), `deliveryFee`, `total` (`subtotal - discount + deliveryFee`), `status`, `paymentMethod` (COD), `notes?` (the customer's own note), `source` (`website`, `facebook`, `whatsapp`, `phone` or `other`; orders saved before 2026-10-13 read as `website`), `courier?` (`name` `"Steadfast"`, `consignmentId`, `trackingCode`, `status` (Steadfast's own delivery status, for example `in_review`, `pending`, `hold`, `delivered`, `cancelled`), `bookedAt`, `statusCheckedAt`; present once the parcel is booked), `returnedAt?`, `createdAt`, `updatedAt`.
Admin-only fields, returned by the admin routes and never by `POST /orders` or `GET /orders/:orderNumber`: `internalNotes[]` (`text`, `by`, `byId`, `at`), `statusHistory[]` (`from?`, `to`, `by`, `byId?`, `at`) `editHistory[]` (`changes[]` of `{ field, from?, to? }`, `by`, `byId`, `at`), `cancelReason?` (why it was cancelled or the parcel came back) `restocked?` (whether a refused parcel went back into stock) `createdBy?` (email of the admin who entered a manual order) and `callConfirmed?` (`by`, `byId?`, `at`: the admin who called the customer and confirmed the order; missing until someone does, set on manual orders from the start). `by` is the admin's email, or `customer` for the order being placed; `byId` is the admin id. All three are append-only and are empty arrays on orders placed before 2026-10-13.
Statuses: `Pending`, `Processing`, `Shipped`, `Delivered`, `Cancelled`, `Returned`.

### `POST /orders` (public, guest checkout)
Body:
```json
{ "customerName": "string", "phone": "01XXXXXXXXX", "address": "string (5-500)",
  "district": "Dhaka", "deliveryArea": "inside_dhaka", "notes": "optional",
  "items": [{ "productId": "string", "quantity": 1 }] }
```
`district` (one of the names in `GET /orders/delivery-fee` `districts`) and `deliveryArea` are optional so an older client still works. Only district `Dhaka` can be `inside_dhaka` (Dhaka city); Dhaka suburbs send `outside_dhaka`. Any other district is stored as `outside_dhaka` whatever is sent, and asking for `inside_dhaka` with it returns `400`. With neither field the order is `inside_dhaka`.
`phone` must be 11 digits starting `01`. 1 to 50 items, quantity 1 to 99. The server loads each product, uses its current `price` (never `compareAtPrice`), checks that it is available (`inStock`) and has enough stock, adds the delivery fee for the order's `deliveryArea`, and stores the order as `Pending`. When stock is short and the product has `allowPreorder`, the whole line is stored with `preorder: true` and the product's `preorderDays` instead of being refused.
Records the first `statusHistory` entry (`to: Pending`, `by: customer`). Returns `201 { data: Order }` without the admin-only fields. Errors: `400` for invalid data, a removed product, a product switched off for sale, or insufficient stock (message names the product). `429` when this `phone` already has 3 `Pending` website orders (checkout can't prove the phone belongs to the person ordering, so each order waits for a confirmation call), or after 5 orders an hour from one address.

### `POST /orders/manual` (orders.edit)
Enters an order taken by Facebook, WhatsApp or phone. Body (strict, unknown fields such as `total` or `price` rejected): the same fields as `POST /orders`, plus:
```json
{ "source": "facebook | whatsapp | phone | other", "deliveryFeeOverride": 0, "discount": 500 }
```
`source` is required. `district` and `deliveryArea` follow the checkout rule; the fee is the one for that area unless `deliveryFeeOverride` (optional, whole taka 0 to 10000) replaces it for this order. `discount` (optional, whole taka, default 0) comes off the items and cannot be more than the subtotal. Items are priced and checked exactly like `POST /orders` (database prices, `inStock`, stock or pre-order). The order is stored as `Pending` with `createdBy` set to the admin's email and `callConfirmed` set to that admin (they took the order from the customer); confirming it takes stock like any other order. Not rate-limited, and it sends no new-order email.
The first `statusHistory` entry names the admin who entered it. Returns `201 { data: Order }`. Errors: `400` for invalid data, a discount above the subtotal, or the same product and stock errors as checkout; `401` without an admin token.

### `GET /orders/delivery-fee` (public)
Returns `{ data: { deliveryFee, zones: { inside_dhaka, outside_dhaka }, districts: string[] } }`. `zones` holds the fee per area, the same amounts orders are charged; `deliveryFee` repeats the inside-Dhaka fee for older clients. `districts` is the 64-district list checkout offers. Fees come from `.env` `DELIVERY_FEE_INSIDE_DHAKA` and `DELIVERY_FEE_OUTSIDE_DHAKA` (placeholder defaults 70 and 130 until the owner sets real ones); the old `DELIVERY_FEE` is still read as the inside-Dhaka fee.

### `GET /orders/:orderNumber?phone=01XXXXXXXXX` (public)
Order number and phone together act as the guest's credentials. The order includes `courier` (with the tracking code) once booked. Missing phone returns `400`, and so does anything other than exactly one phone in the checkout format (a repeated `?phone=`, an object, a malformed number); wrong phone or unknown order returns the same `404 Order not found`. The admin-only fields are left out.

### `GET /orders` (orders.view)
Query: `page` (1), `limit` (20, max 100), `status`, `deliveryArea` (`inside_dhaka` also matches older orders without an area), `source` (`website` also matches older orders without a source), `search` (up to 100 characters; partial, case-insensitive match on order number, customer name or phone, taken literally), `from` and `to` (days the order was placed, `YYYY-MM-DD` in Bangladesh time, both included, either can be left out). Filters combine; bad values fall back to defaults (a bad date is ignored). Returns `{ data: Order[], serverTime, pagination: { page, limit, total, pages } }`, newest first; `total` counts every match across pages.
`updatedSince` (optional, ISO date-time such as `2026-10-13T07:45:00.000Z`) returns only orders created or changed at or after that time, oldest change first; an invalid value returns `400`. `serverTime` is the server's clock when the request started: pass it as the next `updatedSince` so nothing is missed, whatever the client's own clock says.

### `PATCH /orders/:id` (orders.edit)
Corrects contact and delivery details. Body (strict, unknown fields rejected, at least one field): `customerName`, `phone`, `address`, `notes`, `district`, `deliveryArea`. Items, prices and totals cannot be edited. `district` and `deliveryArea` follow the checkout rule and can change only while the order is `Pending` (`409` after). When the area changes, the API sets `deliveryFee` to the current fee for the new area (replacing any agreed manual fee) and recomputes `total`, keeping any `discount`; a district change within the same area keeps the fee charged at checkout. Fields that really change are recorded in `editHistory` with their old and new values and the admin who changed them, including a `deliveryFee` and `total` the API recomputed. Returns `{ data: Order }`, `400` for an inside-Dhaka area with another district, `404` if unknown, or `409` when the order is `Delivered`, `Cancelled` or `Returned`, or when someone else changed the same order at the same moment.

### `PATCH /orders/:id/status` (orders.edit)
Body `{ "status": "<status>", "reason"?, "restock"? }`. Orders only move forward: `Pending` to `Processing` or `Cancelled`; `Processing` to `Shipped` or `Cancelled`; `Shipped` to `Delivered` or `Returned` (parcel refused at the door). `Delivered`, `Cancelled` and `Returned` are final: the shop takes no returns after delivery (customers check the parcel before paying).

- `reason` (max 300 characters, stored as `cancelReason`): required for `Returned`, optional for `Cancelled`, `400` on any other status.
- `restock` (boolean, default `true`): `Returned` only. `false` leaves stock alone, for a saree that came back damaged.
- Moving to `Returned` sets `returnedAt` and `restocked`.

Any other change, including the same status again, returns `409` naming the allowed statuses. When two admins change the same order at once, the second gets `409`. Each change adds a `statusHistory` entry in the same update, removed again if the change is refused for lack of stock. Stock rules:
- `Pending` to `Processing`: stock is decremented atomically for every line that is not a pre-order. A line whose stock ran out since the order was placed becomes a pre-order when its product has `allowPreorder`; otherwise the request returns `409` and nothing changes.
- `Processing` to `Cancelled`: stock is restored for lines that are not pre-orders.
- `Shipped` to `Returned`: stock is restored for lines that are not pre-orders, unless `restock` is `false`.
- Pre-order lines never take or return stock: a piece bought for a pre-order is not added to `stock`.

Cancelling an order booked with Steadfast does not cancel the parcel at Steadfast; that is done in the Steadfast merchant portal.

### `POST /orders/:id/courier/steadfast` (orders.edit)
No body. Books the parcel with the Steadfast merchant API: invoice is the `orderNumber`, recipient name, phone, address (with the order's `district` added when the address doesn't name it) and `notes` come from the order, and the cash to collect is the order's `total`. Only `Processing` orders can be booked. Returns `201 { data: Order }` with `courier` filled in. The order's own `status` does not change. Errors:
- `409`: the order is not `Processing`, is already booked (the message names the tracking code), or is being booked by another request right now.
- `400`: the address is longer than Steadfast's 250 characters (shorten it with `PATCH /orders/:id` first).
- `404`: unknown order.
- `502`: Steadfast refused the booking, timed out or could not be reached; the message carries Steadfast's reason and the order stays bookable.
- `503 Steadfast courier is not configured on the server`: `STEADFAST_API_KEY` or `STEADFAST_SECRET_KEY` is missing.

### `POST /orders/:id/courier/steadfast/refresh` (orders.edit)
No body. Asks Steadfast for the parcel's current delivery status and saves it in `courier.status` and `courier.statusCheckedAt`. Does not change the order's own `status`. Returns `{ data: Order }`, `409` if the order was never booked, `404`, `502` or `503` as above.

### `PATCH /orders/:id/call-confirmed` (orders.edit)
Body (strict) `{ "confirmed": true }` or `{ "confirmed": false }`. `true` stamps `callConfirmed` with the admin and time; `false` removes it. Each real change adds an `editHistory` entry with field `callConfirmed` from `no`/`yes` to `yes`/`no`; sending the current value changes nothing. Returns `{ data: Order }`, `400` for a bad body, `404` if the order is unknown, or `409` for a `Delivered`, `Cancelled` or `Returned` order or when someone else changed it at the same moment. The API does not require it before `Processing`; the admin panel asks first.

### `POST /orders/:id/notes` (orders.edit)
Body `{ "text": "string" }`, trimmed, 1 to 500 characters. Appends a private note stamped with the admin and time; allowed at any status. Notes cannot be edited or deleted. Returns `201 { data: Order }`, `400` for a bad note or id, or `404` if the order is unknown.

## Auth

### `POST /auth/login`
Body `{ email, password }`. Returns `{ data: { token, admin: { id, email, name, role, permissions } } }`; `permissions` is what this person can do (every permission for owners). The token carries `id`, `email`, `role` and `tv` (the account's token version); the admin panel reads access from `GET /auth/me`, not from the token. Wrong credentials return `401 Invalid email or password`; the right password on a switched-off account returns `403`.

### `GET /auth/me` (admin)
Returns `{ data: { _id, email, name, role, permissions, customized, active, createdAt, updatedAt } }` (never the password hash or token version). `permissions` is what this person can do now; `customized` is true when their ticks differ from their role's preset. The admin panel re-reads it on every page change.

### `PATCH /auth/password` (admin)
Body `{ currentPassword, newPassword }` (new password 8 to 100 characters, must differ from the current one; unknown fields rejected). Returns `{ success, data: { token }, message }`. Every earlier token for this account stops working (sign out everywhere); the returned token keeps the current browser signed in. Wrong current password returns `401 Current password is incorrect`. Shares the login rate limit (5 per 15 min).

## Team (owner)

Admin logins and what each person can do. Every route is owner only. Accounts that had the old `admin` role become `owner` when the API starts.

Team member object: `{ _id, email, name, role, permissions, customized, active, createdAt, updatedAt }`.

### `GET /admins` (owner)
Everyone with a login, oldest first. Returns `{ data: [member] }`.

### `POST /admins` (owner)
Body (strict): `email`, `name` (1 to 80 characters), `role` (`owner`, `manager`, `staff` or `viewer`), `password` (temporary, 8 to 100 characters), and optional `permissions` (a list from the table above; left out, the role's preset). Returns `201 { data: member }`; `409` when the email is taken.

### `PATCH /admins/:id` (owner)
Body (strict, at least one field): `name`, `role`, `permissions`, `active`. A new `role` without `permissions` resets them to that role's preset ("Reset to role"); `permissions` replaces the person's ticks. Changes apply on the person's next request; switching off also signs them out at once. Sending `permissions` for an owner returns `400` (owners have everything). Demoting or switching off the last active owner returns `409`. `404` for an unknown or malformed id.

### `POST /admins/:id/reset-password` (owner)
Body `{ password }` (8 to 100 characters). Sets a new temporary password and signs that person out everywhere. Returns `{ success, message }`; `400` for your own account (use `PATCH /auth/password`), `404` when missing.

## Uploads

### `POST /uploads/signature` (products.edit)
No body. Returns `{ data: { cloudName, apiKey, timestamp, folder, signature } }` so the admin panel can send a product photo straight to Cloudinary (`POST https://api.cloudinary.com/v1_1/<cloudName>/image/upload` with `file`, `api_key`, `timestamp`, `folder`, `signature`). The photo never passes through this API and the Cloudinary secret is never returned. Cloudinary accepts a signature for about 1 hour. Its `secure_url` reply is what goes into the product's `images`. Returns `503 Image upload is not configured on the server` when the `CLOUDINARY_*` variables are missing.

## Settings

Shop-wide settings the owner edits on the admin Settings page. One document, created with the defaults on first read and cached in the API for 60 seconds (a save clears the cache). Delivery fees are not here; see `GET /orders/delivery-fee`.

| Field | Type | Default | Public |
|---|---|---|---|
| `whatsappNumber` | string, `8801[3-9]XXXXXXXX` | `8801700000000` (placeholder) | yes |
| `supportPhone` | string, `01[3-9]XXXXXXXX` or `""` | `""` | yes |
| `announcementText` | string, up to 120 characters | `Shop the festive collection` | yes |
| `announcementActive` | boolean | `true` | yes |
| `lowStockThreshold` | integer 0 to 1000; products with fewer pieces count as low stock | `6` | no |

### `GET /settings` (public)
Returns `{ data: { whatsappNumber, supportPhone, announcementText, announcementActive } }`. Never includes admin-only fields. The storefront caches it for 60 seconds and falls back to the defaults when the API is unreachable.

### `GET /settings/admin` (admin)
Open to every signed-in team member (nothing in it is secret, and the admin needs the low-stock limit). Returns `{ data: <every field above>, updatedAt }`.

### `PATCH /settings` (settings.edit)
Body: any subset of the fields above (strict: unknown fields and an empty body return `400`). Returns `{ data: <every field>, message: "Settings saved" }`. Also `400` when the announcement would be switched on with empty text.

## Courier payments

Cash on delivery money reaches the shop through the courier, days after delivery, minus the courier's charges. These routes record each payout by hand from the courier's statement; they do not call any courier API. Reading needs `payments.view`; recording or deleting needs `payments.edit`. Money is in taka, rounded to 2 decimals on the server.

Payment object: `{ _id, courier, paidAt, method?, reference?, lines: [{ order, orderNumber, orderTotal, collected, charge, net }], collectedTotal, chargeTotal, netTotal, amountReceived, difference, notes?, recordedBy?, createdAt, updatedAt }`. `orderTotal` is the order's total when the payment was recorded; `net = collected - charge` (negative for a refused parcel that only cost a return charge); `difference = amountReceived - netTotal` (anything but 0 means the money that arrived does not match the statement). `method` is one of `Bank transfer`, `bKash`, `Nagad`, `Cash`, `Other`.

### `GET /courier-payments/unpaid` (payments.view)
Delivered orders that no payment covers yet, oldest update first. Returns `{ data: { orders: [{ _id, orderNumber, customerName, phone, total, status, createdAt, updatedAt }], count, expectedTotal } }`; `expectedTotal` is the sum of the order totals.

### `GET /courier-payments` (payments.view)
Query: `page` (default 1), `limit` (default 20, max 100). Newest `paidAt` first. Returns `{ data: [payment], summary: { collectedTotal, chargeTotal, netTotal, amountReceived }, pagination }`; `summary` covers every payment, not just the page.

### `GET /courier-payments/:id` (payments.view)
One payment. `404` when missing, `400` for a malformed id.

### `POST /courier-payments` (payments.edit)
Body (strict, unknown fields are a `400`): `paidAt` (date, not in the future), `lines: [{ orderNumber, collected, charge }]` (1 to 500), and optional `courier` (default `Steadfast`), `method`, `reference` (up to 100 characters), `amountReceived` (defaults to the computed net), `notes` (up to 500). The server looks up each order and computes `orderTotal`, every `net` and every total. Each order must be `Shipped`, `Delivered` or `Returned` (`400` otherwise or when not found), may appear once in the body (`400`) and in one payment ever (`409`; a unique index also blocks two admins recording it at the same moment). Returns `201` with the payment.

### `DELETE /courier-payments/:id` (payments.edit)
Removes a payment entered by mistake; its orders show as unpaid again. `404` when missing.

## Customers

Checkout is guest-only, so a customer is a phone number; these routes add up its orders. Reading needs `orders.view`; blocking needs `orders.edit`. `spent` (the total of Delivered orders) is only sent with `money.view`.

Customer object: `{ phone, name, address, district?, orders, delivered, cancelled, returned, spent?, firstOrderAt, lastOrderAt, risky, blocked }`. `name`, `address` and `district` come from the newest order. `risky` is true when `returned + cancelled` is 2 or more. `blocked` is `{ note?, by, at }` or `null`.

A blocked phone's orders are **still accepted** (owner decision 2026-10-15); the customer is never told. The admin order list (`GET /orders`) adds `blockedPhone: { note?, by, at }` to each order from a blocked phone so the admin shows it in red; no public response includes it.

### `GET /customers` (orders.view)
Query: `page` (1), `limit` (25, max 100), `search` (partial, case-insensitive match on phone or any order's name), `sort` (`recent` latest order first, `orders` most orders, `refused` most returned plus cancelled), `blocked` (`true` for blocked phones only). Bad values fall back to defaults. Returns `{ data: Customer[], pagination: { page, limit, total, pages } }`.

### `GET /customers/:phone` (orders.view)
Returns `{ data: { customer, orders: [{ _id, orderNumber, customerName, status, total, createdAt }] } }` with the latest 50 orders, newest first. `400` for a phone that isn't 11 digits starting with 01; `404` when the phone has no orders and isn't blocked.

### `PUT /customers/:phone/block` (orders.edit)
Body (strict): `{ blocked: boolean, note?: string }` (note up to 300 characters). `blocked: true` blocks or re-blocks (replacing the note and who did it); `false` removes the block. Returns `{ data: { phone, blocked } }`. `400` for a bad phone or body.

## Statistics

### `GET /stats` (orders.view; money with money.view)
The admin dashboard's numbers, worked out from every order **placed** in the range. Query: `from`, `to` as `YYYY-MM-DD` days in Bangladesh time (UTC+6), both included; default the last 30 days ending today; at most 366 days. A bad date, `from` after `to` or a longer range returns `400`.

Response `data`:

| Field | Notes |
|---|---|
| `range` | `{ from, to, days }` |
| `orders` | `total`, `byStatus` (every status), `bySource` (every source), `byArea` (`inside_dhaka`, `outside_dhaka`; orders from before areas count as inside), `withPreorder`, `refusedRate` (Returned as a percent of Delivered + Returned, `null` when none) |
| `pipeline` | Current work whatever the date: `toConfirm` (Pending), `toShip` (Processing), `onTheWay` (Shipped), `preordersWaiting` (Processing orders with a pre-order line) |
| `daily` | One entry per day of the range: `{ date, orders, value }`; `value` is the total of orders not Cancelled or Returned |
| `bestSellers` | Top 10 by quantity among orders not Cancelled or Returned: `{ productId, name, quantity, value }` |
| `topDistricts` | Top 10 `{ district, orders }` |
| `money` | Only with `money.view`: `deliveredRevenue` and `deliveredOrders` (Delivered), `orderValue` and `averageOrderValue` (not Cancelled or Returned), `deliveryFees` (Delivered), `cost`, `grossProfit` (Delivered orders whose every line has a cost price: subtotal minus discount minus cost, before courier charges), `profitOrders`, `unknownCostOrders`, `courierOwes: { orders, total }` (Delivered orders on no courier payment, from any date) |

Without `money.view`, `money` and every `value` field are left out.

## Changelog

- 2026-10-13: Steadfast courier booking. Orders gain an optional `courier` object; new admin routes `POST /orders/:id/courier/steadfast` and `POST /orders/:id/courier/steadfast/refresh` (coovi-api#18).

- 2026-10-15: deleting a product also deletes its photos from Cloudinary; the storefront no longer puts the customer's phone in the order page link (`/order-confirmation/<number>`; the phone is kept in a cookie for that page) (coovi-api, coovi-storefront, branch `claude/project-thread-deqibw`).

- 2026-10-15: phone check by call: `POST /orders` returns `429` when the phone already has 3 `Pending` website orders, and order creation is limited to 5 an hour per address (was 20); orders gain admin-only `callConfirmed`, set with the new `PATCH /orders/:id/call-confirmed` and from the start on manual orders (coovi-api, coovi-admin, coovi-storefront, branch `claude/checkout-phone-check-f5pfyv`).

- 2026-10-15: customers and block list: new `GET /customers`, `GET /customers/:phone` and `PUT /customers/:phone/block`; the admin order list adds `blockedPhone` to orders from a blocked phone, which are still accepted (coovi-api#34, coovi-admin#28).

- 2026-10-20: products gain an optional `shareImage` (`https://`, 1200x630) for social media link previews; cleared when a `PUT` leaves it out, deleted from Cloudinary with the product (coovi-api, coovi-admin, coovi-storefront, branch `claude/social-share-previews-kg0ucw`).

- 2026-10-15: `GET /orders` gains `search`, `source`, `from` and `to`; the admin loads one page of orders at a time (coovi-api#33, coovi-admin#27).

- 2026-10-15: statistics dashboard: new `GET /stats`; products gain an admin-only `costPrice` (`GET /products/:id/cost`, set on create and update with `money.view`), copied onto order lines and never sent back (coovi-api#32, coovi-admin#26).

- 2026-10-15: roles (owner, manager, staff, viewer) with per-person View and Edit permissions, checked on every admin route, and sign out everywhere. New `/admins` team routes; `GET /auth/me` and the login response return `permissions`; `PATCH /auth/password` returns a fresh token and signs out every other session; tokens now carry `tv` and older tokens stop working once after deploy (sign in again) (coovi-api, coovi-admin, branch `claude/project-thread-deqibw`).

- 2026-10-13: security review fixes: `createdBy` is now admin-only (left out of `POST /orders` and `GET /orders/:orderNumber`); product `images` must be `https://`; `POST /auth/login` returns `400` for non-string fields; duplicate product lines in an order are merged before the stock check (coovi-api#23).

- 2026-10-13: added `/courier-payments` (record courier COD payouts by hand, list delivered orders still unpaid). Orders are unchanged (coovi-api#20, coovi-admin#13).

- 2026-10-13: `Returned` status for parcels refused at the door, with stock put back; `PATCH /orders/:id/status` gains `reason` and `restock`; orders gain `returnedAt` and admin-only `cancelReason` and `restocked`. No returns after delivery: `Delivered` stays final (coovi-api#17).

- 2026-10-13: private order notes and change history. Added `POST /orders/:id/notes`; orders gain admin-only `internalNotes`, `statusHistory` and `editHistory`, left out of public responses (coovi-api#16).

- 2026-10-13: delivery fee by area: orders gain `district` and `deliveryArea`; `GET /orders/delivery-fee` adds `zones` and `districts`; `GET /orders` filters by `deliveryArea`; `PATCH /orders/:id` can change the area while Pending (coovi-api#14, coovi-admin#16, coovi-storefront#15).

- 2026-10-13: manual order entry: `POST /orders/manual`; orders gain `source`, `createdBy` and `discount` (coovi-api#21, coovi-admin#15, coovi-storefront#14).

- 2026-10-13: shop settings: `GET /settings`, `GET /settings/admin`, `PATCH /settings` (coovi-api#22, coovi-admin#14, coovi-storefront#13).

- 2026-10-13: storefront server rate limit via `x-coovi-storefront-key` and `x-coovi-client-ip` (coovi-api#19, coovi-storefront#11). Responses unchanged.

- 2026-10-13: `PUT /products/:id` keeps `category`, `inStock`, `allowPreorder` and `preorderDays` when left out instead of resetting them to their defaults (coovi-api#13).

- 2026-10-13: `GET /orders` gains `updatedSince` and returns `serverTime`, so the admin refreshes only changed orders (coovi-api#10).

- 2026-10-13: pre-orders. Products gain `allowPreorder` and `preorderDays`; order items gain `preorder` and `preorderDays` (coovi-api#9).

- 2026-10-13: documented that `PUT /products/:id` resets `category`, `inStock`, `allowPreorder` and `preorderDays` to their defaults when left out (behavior unchanged).

- 2026-10-12: added `POST /uploads/signature` (admin photo upload through Cloudinary). The product `images` field is unchanged: still an array of URLs.

- 2026-10-06 (documented 2026-10-07): added `PATCH /orders/:id`; order status is forward-only (`409` otherwise); orders reject products switched off for sale; `GET /orders` limit capped at 100; product `price` minimum 1; `PUT /products/:id` clears omitted optional fields.

- 2026-10-04: added `PATCH /auth/password` and `GET /health`.

- 2026-10-04: added `compareAtPrice` on products and `GET /products?onSale=true` (sale pricing; order totals unchanged).
