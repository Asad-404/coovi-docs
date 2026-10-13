# COOVI API Contract

Canonical contract shared by `coovi-api`, `coovi-storefront` and `coovi-admin`. Base URL (dev): `http://localhost:5000/api`.
Source of truth is the code in `coovi-api/src/routes/`; update this file in the same change as any route change.

## Conventions

- Every response is JSON: `{ "success": boolean, "data"?, "message"?, "errors"?, "pagination"? }`.
- Validation failures return `400` with `errors: ["field: reason", ...]`. Unknown routes return `404` JSON.
- Money is whole BDT (integers). Dates are ISO strings.
- Admin routes need `Authorization: Bearer <JWT>` (token from `POST /auth/login`, expires in 1 day). Missing or bad token returns `401`.
- Rate limits (per IP): reads 100/min, login 5 per 15 min, order creation 20/hour, order lookup 20/min. Exceeding returns `429`.
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
| `size?` | string | |
| `category` | string | default `Saree` |
| `stock` | number | |
| `inStock` | boolean | |
| `allowPreorder` | boolean | default `false`. When on, the product can still be ordered when stock is short; the line becomes a pre-order |
| `preorderDays` | number | 1 to 90, default 15: the promised wait for a pre-order |
| `createdAt`, `updatedAt` | string | |

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

### `GET /products/:slug` (public)
Returns `{ success, data: Product }`, or `404` `Product not found`.

### `POST /products` (admin)
Body (strict, unknown fields rejected): `slug`, `name`, `price`, `images`, `stock` required; `nameBn`, `description`, `descriptionBn`, `size`, `category` (default `Saree`), `inStock` (default `true`), `compareAtPrice`, `allowPreorder` (default `false`), `preorderDays` (whole number 1 to 90, default 15) optional.
`price` is a whole number of at least 1. `compareAtPrice` must be greater than `price`. Returns `201 { data: Product }`; duplicate slug returns `400`.

### `PUT /products/:id` (admin)
Same body as create (full replacement of the listed fields). Optional fields left out (`nameBn`, `description`, `descriptionBn`, `size`, `compareAtPrice`) are cleared. Send `compareAtPrice: null`, or leave it out, to remove a discount. The settings `category`, `inStock`, `allowPreorder` and `preorderDays` keep their saved value when left out (the create defaults are not applied on update). Returns `{ data: Product }`, `400` for invalid data or a duplicate slug, or `404`.

### `DELETE /products/:id` (admin)
Returns `{ success, message }` or `404`.

## Orders

Order object: `_id`, `orderNumber` (`ORD-YYYYMMDD-XXXXXX`: the order's date in Bangladesh time, then 6 random characters from `23456789ABCDEFGHJKMNPQRSTVWXYZ`; orders placed before 2026-10-13 keep the older `ORD-YYYYMMDD-NNN`), `customerName`, `phone`, `address` (string), `district?` (one of the 64 districts; missing on orders placed before delivery areas), `deliveryArea` (`inside_dhaka` or `outside_dhaka`; older orders without it count as `inside_dhaka`), `items[]` (`productId`, `name`, `price`, `quantity`, `image`, `size?`, copied from the product at order time; `preorder` (boolean) and `preorderDays?` mark a line sourced for the customer), `subtotal`, `discount` (taka off the items, `0` unless an admin agreed one on a manual order), `deliveryFee`, `total` (`subtotal - discount + deliveryFee`), `status`, `paymentMethod` (COD), `notes?` (the customer's own note), `source` (`website`, `facebook`, `whatsapp`, `phone` or `other`; orders saved before 2026-10-13 read as `website`), `returnedAt?`, `createdAt`, `updatedAt`.
Admin-only fields, returned by the admin routes and never by `POST /orders` or `GET /orders/:orderNumber`: `internalNotes[]` (`text`, `by`, `byId`, `at`), `statusHistory[]` (`from?`, `to`, `by`, `byId?`, `at`) `editHistory[]` (`changes[]` of `{ field, from?, to? }`, `by`, `byId`, `at`), `cancelReason?` (why it was cancelled or the parcel came back) `restocked?` (whether a refused parcel went back into stock) and `createdBy?` (email of the admin who entered a manual order). `by` is the admin's email, or `customer` for the order being placed; `byId` is the admin id. All three are append-only and are empty arrays on orders placed before 2026-10-13.
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
Records the first `statusHistory` entry (`to: Pending`, `by: customer`). Returns `201 { data: Order }` without the admin-only fields. Errors: `400` for invalid data, a removed product, a product switched off for sale, or insufficient stock (message names the product).

### `POST /orders/manual` (admin)
Enters an order taken by Facebook, WhatsApp or phone. Body (strict, unknown fields such as `total` or `price` rejected): the same fields as `POST /orders`, plus:
```json
{ "source": "facebook | whatsapp | phone | other", "deliveryFeeOverride": 0, "discount": 500 }
```
`source` is required. `district` and `deliveryArea` follow the checkout rule; the fee is the one for that area unless `deliveryFeeOverride` (optional, whole taka 0 to 10000) replaces it for this order. `discount` (optional, whole taka, default 0) comes off the items and cannot be more than the subtotal. Items are priced and checked exactly like `POST /orders` (database prices, `inStock`, stock or pre-order). The order is stored as `Pending` with `createdBy` set to the admin's email; confirming it takes stock like any other order. Not rate-limited, and it sends no new-order email.
The first `statusHistory` entry names the admin who entered it. Returns `201 { data: Order }`. Errors: `400` for invalid data, a discount above the subtotal, or the same product and stock errors as checkout; `401` without an admin token.

### `GET /orders/delivery-fee` (public)
Returns `{ data: { deliveryFee, zones: { inside_dhaka, outside_dhaka }, districts: string[] } }`. `zones` holds the fee per area, the same amounts orders are charged; `deliveryFee` repeats the inside-Dhaka fee for older clients. `districts` is the 64-district list checkout offers. Fees come from `.env` `DELIVERY_FEE_INSIDE_DHAKA` and `DELIVERY_FEE_OUTSIDE_DHAKA` (placeholder defaults 70 and 130 until the owner sets real ones); the old `DELIVERY_FEE` is still read as the inside-Dhaka fee.

### `GET /orders/:orderNumber?phone=01XXXXXXXXX` (public)
Order number and phone together act as the guest's credentials. Missing phone returns `400`, and so does anything other than exactly one phone in the checkout format (a repeated `?phone=`, an object, a malformed number); wrong phone or unknown order returns the same `404 Order not found`. The admin-only fields are left out.

### `GET /orders` (admin)
Query: `page` (1), `limit` (20, max 100), `status`, `deliveryArea` (`inside_dhaka` also matches older orders without an area); bad values fall back to defaults. Returns `{ data: Order[], serverTime, pagination: { page, limit, total, pages } }`, newest first.
`updatedSince` (optional, ISO date-time such as `2026-10-13T07:45:00.000Z`) returns only orders created or changed at or after that time, oldest change first; an invalid value returns `400`. `serverTime` is the server's clock when the request started: pass it as the next `updatedSince` so nothing is missed, whatever the client's own clock says.

### `PATCH /orders/:id` (admin)
Corrects contact and delivery details. Body (strict, unknown fields rejected, at least one field): `customerName`, `phone`, `address`, `notes`, `district`, `deliveryArea`. Items, prices and totals cannot be edited. `district` and `deliveryArea` follow the checkout rule and can change only while the order is `Pending` (`409` after). When the area changes, the API sets `deliveryFee` to the current fee for the new area (replacing any agreed manual fee) and recomputes `total`, keeping any `discount`; a district change within the same area keeps the fee charged at checkout. Fields that really change are recorded in `editHistory` with their old and new values and the admin who changed them, including a `deliveryFee` and `total` the API recomputed. Returns `{ data: Order }`, `400` for an inside-Dhaka area with another district, `404` if unknown, or `409` when the order is `Delivered`, `Cancelled` or `Returned`, or when someone else changed the same order at the same moment.

### `PATCH /orders/:id/status` (admin)
Body `{ "status": "<status>", "reason"?, "restock"? }`. Orders only move forward: `Pending` to `Processing` or `Cancelled`; `Processing` to `Shipped` or `Cancelled`; `Shipped` to `Delivered` or `Returned` (parcel refused at the door). `Delivered`, `Cancelled` and `Returned` are final: the shop takes no returns after delivery (customers check the parcel before paying).

- `reason` (max 300 characters, stored as `cancelReason`): required for `Returned`, optional for `Cancelled`, `400` on any other status.
- `restock` (boolean, default `true`): `Returned` only. `false` leaves stock alone, for a saree that came back damaged.
- Moving to `Returned` sets `returnedAt` and `restocked`.

Any other change, including the same status again, returns `409` naming the allowed statuses. When two admins change the same order at once, the second gets `409`. Each change adds a `statusHistory` entry in the same update, removed again if the change is refused for lack of stock. Stock rules:
- `Pending` to `Processing`: stock is decremented atomically for every line that is not a pre-order. A line whose stock ran out since the order was placed becomes a pre-order when its product has `allowPreorder`; otherwise the request returns `409` and nothing changes.
- `Processing` to `Cancelled`: stock is restored for lines that are not pre-orders.
- `Shipped` to `Returned`: stock is restored for lines that are not pre-orders, unless `restock` is `false`.
- Pre-order lines never take or return stock: a piece bought for a pre-order is not added to `stock`.

### `POST /orders/:id/notes` (admin)
Body `{ "text": "string" }`, trimmed, 1 to 500 characters. Appends a private note stamped with the admin and time; allowed at any status. Notes cannot be edited or deleted. Returns `201 { data: Order }`, `400` for a bad note or id, or `404` if the order is unknown.

## Auth

### `POST /auth/login`
Body `{ email, password }`. Returns `{ data: { token, admin: { id, email, name, role } } }`. Wrong credentials return `401 Invalid email or password`.

### `GET /auth/me` (admin)
Returns `{ data: Admin }` without the password hash.

### `PATCH /auth/password` (admin)
Body `{ currentPassword, newPassword }` (new password 8 to 100 characters, must differ from the current one; unknown fields rejected). Returns `{ success, message }`. Wrong current password returns `401 Current password is incorrect`. Shares the login rate limit (5 per 15 min).

## Uploads

### `POST /uploads/signature` (admin)
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
Returns `{ data: <every field above>, updatedAt }`.

### `PATCH /settings` (admin)
Body: any subset of the fields above (strict: unknown fields and an empty body return `400`). Returns `{ data: <every field>, message: "Settings saved" }`. Also `400` when the announcement would be switched on with empty text.

## Changelog

- 2026-10-13: security review fixes: `createdBy` is now admin-only (left out of `POST /orders` and `GET /orders/:orderNumber`); product `images` must be `https://`; `POST /auth/login` returns `400` for non-string fields; duplicate product lines in an order are merged before the stock check (coovi-api#23).

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
