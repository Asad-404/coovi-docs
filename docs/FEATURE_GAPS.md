# Missing business features

Which features a Bangladesh cash-on-delivery saree shop needs, and whether Coovi has them today. Written 2026-10-13 (states re-checked against GitHub on 2026-10-15) by reading the code in all three apps and comparing it with `docs/ADMIN_FEATURE_PLAN.md`. Safety and hosting gaps (backups, rate limits, domain) are in `docs/GO_LIVE_CHECKLIST.md`, not here.

## How to read this file

- **State**: **Have** (built and working), **Partial** (some of it exists), **Missing** (not built).
- **Priority**: **P1** needed to start selling for real, **P2** needed in the first month of real orders, **P3** worth adding as the shop grows.
- **Plan**: the feature number in `docs/ADMIN_FEATURE_PLAN.md`, or **New** when the plan does not cover it yet.
- What a shop "needs" here is Claude's judgement from how Bangladesh COD shops usually run (Facebook-led sales, courier delivery, confirmation calls). It is not checked against your own sales; change priorities to match how you actually sell.

## Summary

| | Have | Built, waiting on you or in review | Partial | Missing |
|---|---|---|---|---|
| Customer side (storefront) | 8 | 1 | 4 | 12 |
| Running orders (admin) | 11 | 2 | 2 | 9 |
| Selling and marketing | 0 | 0 | 1 | 5 |

P1 status on 2026-10-15: new-order email alerts, pre-orders, district and delivery fee by area, internal notes and history, refused-parcel returns with restock, courier cash collection, shop settings and manual order entry are built and merged. Steadfast booking and the customer order SMS are built and wait on your Steadfast account and your choice of SMS company. The next build order is in `QUICK_STATUS.md` (Backlog).

## Admin feature plan coverage

Every feature in `docs/ADMIN_FEATURE_PLAN.md` (1 to 18) and every unbuilt item in the `QUICK_STATUS.md` backlog appears in the tables below. As of 2026-10-15 features 1, 2, 3, 5, 6, 11 (statistics), 12 (order pages and search), 13 (roles) and 14 are built and merged, 4 (Steadfast) and 8 (customers and block list) are in review, and the rest are not built. The plan's groundwork steps G1 (order logic into services), G2 (public order view) and G3 (who did it) are internal changes with no screen of their own: they get built together with the first feature that needs them (features 2, 3, 10, 13, 14, 15 and 17).

| Plan # | Feature | Table and priority |
|---|---|---|
| 1 | New-order alerts | Admin, P1 |
| 2 | Cancel and return with restock | Admin, P1 |
| 3 | Internal notes and history | Admin, P1 |
| 4 | Courier details | Admin, P1 |
| 5 | Delivery fee by area | Customer, P1 |
| 6 | Shop settings page | Admin, P1 |
| 14 | Manual order entry | Admin, P1 |
| 7 | Categories | Customer, P2 |
| 8 | Customers list | Admin, P2 |
| 9a | Product attributes | Customer, P2 |
| 11 | Reports | Admin, P2 |
| 12 | Orders pagination and search | Admin, P2 |
| 9b | Product variants | Admin, P3 |
| 10 | Discount codes | Customer, P3 |
| 13 | Second admin and roles | Admin, P2 |
| 15 | Bulk actions | Admin, P3 |
| 16 | Homepage banner | Admin, P3 |
| 17 | Stock history log | Admin, P3 |
| 18 | Reviews and back-in-stock | Customer, P3 |

## Customer side (storefront)

| Feature | State | Priority | Plan | Notes |
|---|---|---|---|---|
| Browse, search, sort, sale page | Have | | | `/shop`, `/sale`, search in header. |
| Product page with photo gallery | Have | | | Gallery, quantity, related products. |
| Cart and guest cash-on-delivery checkout | Have | | | Prices and totals from the API. |
| Order confirmation and order tracking by number and phone | Have | | | Tracking has its own page with status steps (coovi-storefront#32). Status only, no courier tracking. |
| Policy pages (returns, delivery, privacy, terms) | Have | | | Wording still needs your real terms (see `QUICK_STATUS.md`). |
| SEO, share cards, sitemap | Have | | | |
| **District and area at checkout** | Have | P1 | 5 | District dropdown with a Dhaka city or suburbs choice. Pull requests coovi-api#14, coovi-admin#16, coovi-storefront#15 (2026-10-13). |
| **Delivery fee by area** | Have | P1 | 5 | Inside Dhaka city and outside Dhaka (suburbs included); placeholder fees 70 and 130 until the owner sets real ones. Same pull requests. |
| **Order confirmation SMS to the customer** | Built, waiting on SMS company | P1 | New | Customers expect an SMS with the order number; it also cuts "did my order go through?" calls. Needs an SMS provider account (for example SSL Wireless, BulkSMSBD). |
| WhatsApp and Messenger chat button | Partial | P1 | | WhatsApp link exists with the placeholder number; no Messenger. |
| Contact form | Partial | P2 | | Contact page has a `mailto:support@coovi.com` link; that address only works once you own the domain. |
| Product details: fabric, colour, length, blouse piece, work | Partial | P2 | 9a | Only `size` exists. Saree buyers filter and decide on fabric and colour. |
| Categories and collections (Jamdani, Katan, Silk, Cotton, occasion) | Missing | P2 | 7 | Everything is "Saree". |
| Filter by price, colour, fabric | Missing | P2 | 9a | Sort only. |
| Bengali language | Partial | P2 | | Bengali product names show where set; menus, checkout and policies are English only. |
| Courier tracking link for the customer | Missing | P2 | 4 | The API already returns the tracking code on the public order lookup; the track-order page does not show it yet. |
| Customer can request a cancellation | Missing | P3 | 2 | Today they must call or message. |
| Discount codes | Missing | P3 | 10 | |
| Advance payment of delivery fee (bKash or Nagad) | Missing | P3 | New | Common way to stop fake COD orders; needs a merchant account. |
| Full online payment (SSLCommerz, bKash) | Missing | P3 | New | |
| Product video | Missing | P3 | New | Sarees sell well on video; Cloudinary can host it. |
| Reviews and back-in-stock requests | Missing | P3 | 18 | |
| Wishlist | Missing | P3 | New | |
| Icon on the mobile header | Missing | P3 | New | Optional item from the `QUICK_STATUS.md` backlog. |
| Customer accounts with order history | Missing | P3 | New | Guest checkout is fine to start; accounts help repeat buyers later. |

## Running orders (admin)

| Feature | State | Priority | Plan | Notes |
|---|---|---|---|---|
| Products: add, edit, delete, photo upload, sale price, stock | Have | | | |
| Orders: list, filter by status and date, search, status changes | Have | | | Status only moves forward; stock taken on confirm. |
| Edit customer contact details on an order | Have | | | |
| CSV export and printable slip | Have | | | |
| **New-order alerts** to you | Have | P1 | 1 | Nothing tells you an order arrived. Owner chose WhatsApp or email: email first (free, simple); WhatsApp needs a WhatsApp Business API account and approved message templates, so it comes later. |
| **Manual order entry** | Have | P1 | 14 | Many orders arrive by Facebook message or phone; today they cannot go into the system, so stock and reports are wrong. |
| **Internal notes and status history** | Have | P1 | 3 | Private notes, status history and detail-edit history with who and when: coovi-api#16, coovi-admin#10. |
| **Courier booking and tracking number** (Steadfast, owner's choice) | Built, waiting on Steadfast account | P1 | 4 | coovi-api#18, coovi-admin#12: "Book with Steadfast" on a Processing order saves the tracking code and courier status. Needs a Steadfast merchant account and its API keys on Render. Not built: automatic status updates (Steadfast webhook), so the admin presses "check" and still marks Shipped and Delivered. |
| **Cancel and return with restock** | Have | P1 | 2 | `Returned` status for parcels refused at the door, with reason and restock (coovi-api#17, coovi-admin#11). No returns after delivery (owner decision). Customer-requested cancellation is still P3. |
| **Pre-orders** | Have | P1 | New | Owner's rule: sell from stock when the saree is in stock; when it is not, take a pre-order that ships in at least 15 days. Needs a per-product "allow pre-order" switch and lead time, a clear "Pre-order, ships in about 15 days" label on the product page, cart and confirmation, pre-order orders marked in the admin, and stock that never goes below zero. Also answers what happens when two people order the last piece: the second becomes a pre-order instead of a failed confirmation. |
| **Cash collection from couriers** | Have | P1 | New | Pull requests coovi-api#20, coovi-admin#13 (2026-10-13). Admin "Courier payments" page: delivered orders the courier has not paid for yet, payouts typed in from the courier's statement with its charge and return costs per parcel, and any shortfall. Manual entry; importing Steadfast's payment statements automatically can come with the courier booking work. |
| **Shop settings page** (WhatsApp number, support phone, announcement text, low-stock limit) | Have | P1 | 6 | Pull requests coovi-api#22, coovi-admin#14, coovi-storefront#13 (2026-10-13). Delivery fees stay with the delivery-by-area work (owner decision 2026-10-13). |
| Dashboard and reports | Have | P2 | 11 | 2026-10-15: server-side statistics for any date range: what needs doing now, money cards, profit, refused rate, best sellers, districts and order sources. |
| Product cost price and profit | Have | P2 | New | 2026-10-15: admin-only cost price on each product, copied onto orders; profit counts delivered orders with a cost price. |
| Customers list and repeat buyers | Have (in review) | P2 | 8 | 2026-10-15: Customers page by phone, with order history in the order window. |
| Fake-order check (block list, courier delivery-success check by phone) | Partial | P2 | 8 (block list), New (courier check) | 2026-10-15: block list merged; blocked numbers' orders are accepted and shown in red. 2026-10-27: "Confirmed by call" tick and at most 3 unconfirmed orders per phone merged (coovi-api#36, coovi-admin#29). The courier delivery-success check still needs a Steadfast account. |
| Real pagination and server search on orders | Have | P2 | 12 | 2026-10-15: the admin loads one page at a time and the API does the search and filters. |
| Staff accounts and roles | In review | P2 | 13 | Four roles with per-person View and Edit access on a Team page, branch `claude/project-thread-deqibw` (2026-10-15). Moved up by the owner. |
| Bulk actions (confirm or print many orders) | Missing | P3 | 15 | |
| Stock history log | Missing | P3 | 17 | |
| Homepage banner from the admin | Missing | P3 | 16 | |
| Product variants (same design, several colours) | Missing | P3 | 9b | Only if you stock repeats; owner is not sure yet, so it stays last. |
| Expenses and simple accounts | Missing | P3 | New | |
| Delete a product's photos from Cloudinary when the product is deleted | Missing | P3 | New | Open item from the photo upload work in `QUICK_STATUS.md`. |

## Selling and marketing

| Feature | State | Priority | Plan | Notes |
|---|---|---|---|---|
| Facebook Pixel and Conversions API | Partial | P2 | New | Browser pixel built 2026-10-20 (PageView, ViewContent, AddToCart, InitiateCheckout, Purchase), off until the Pixel ID is set in Vercel; Conversions API (server copy) waits until ads start (owner decision 2026-10-20). Most saree sales in Bangladesh come from Facebook and Instagram ads; without the pixel you cannot measure or optimise ads. Needs your Meta Business account. Moved from P1 to P2: owner will not run ads during development. |
| Facebook and Instagram product catalogue feed | Missing | P2 | New | Lets you tag products in posts and run catalogue ads. |
| Visitor analytics (Google Analytics or Vercel Analytics) | Missing | P2 | New | |
| Google Search Console and Merchant Center | Partial | P2 | | Product structured data exists; sitemap not yet submitted (needs the real domain). |
| Abandoned-cart follow-up | Missing | P3 | New | Needs the phone before checkout ends, so it is a later step. |
| Newsletter or SMS marketing list | Missing | P3 | New | Needs customer consent. |

## Owner decisions

Answered by the owner on 2026-10-13:

1. Where orders come from: none yet, the shop is still in development. Manual order entry stays P1 but moves to the end of the P1 list.
2. Courier: Steadfast.
3. New-order alerts: WhatsApp or email. Email first, WhatsApp later.
4. Stock: not decided between one-of-a-kind and restocking. For now: sell from stock when in stock, otherwise take a pre-order that ships in at least 15 days (see "Pre-orders").
5. Returns after delivery: not accepted for now (changed 2026-10-13). Customers check the saree in front of the rider and refuse the parcel if something is wrong; a refused parcel's stock goes back.
6. Facebook ads: maybe later, not during development. Facebook Pixel moves to P2.

No return window or refund method is needed while returns after delivery are off.

Answered by the owner on 2026-10-15:

7. Leave the **You** items in `docs/GO_LIVE_CHECKLIST.md` for now; build what has no blockers.
8. Roles and a statistics dashboard come first. Categories, saree details and shop filters are not needed now.
9. Access: fixed roles (owner, manager, staff, viewer) as starting points, and the owner can adjust each person's View and Edit ticks. Staff handle orders and products; only owners manage the team.
10. Blocked phones: accept the order but flag it red in the admin for a confirmation call (not refused at checkout).
