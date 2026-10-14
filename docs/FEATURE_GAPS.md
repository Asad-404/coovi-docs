# Missing business features

Which features a Bangladesh cash-on-delivery saree shop needs, and whether Coovi has them today. Written 2026-10-13 by reading the code in all three apps and comparing it with `docs/ADMIN_FEATURE_PLAN.md`. Safety and hosting gaps (backups, rate limits, domain) are in `docs/GO_LIVE_CHECKLIST.md`, not here.

## How to read this file

- **State**: **Have** (built and working), **Partial** (some of it exists), **Missing** (not built).
- **Priority**: **P1** needed to start selling for real, **P2** needed in the first month of real orders, **P3** worth adding as the shop grows.
- **Plan**: the feature number in `docs/ADMIN_FEATURE_PLAN.md`, or **New** when the plan does not cover it yet.
- What a shop "needs" here is Claude's judgement from how Bangladesh COD shops usually run (Facebook-led sales, courier delivery, confirmation calls). It is not checked against your own sales; change priorities to match how you actually sell.

## Summary

| | Have | Partial | Missing |
|---|---|---|---|
| Customer side (storefront) | 6 | 4 | 15 |
| Running orders (admin) | 4 | 3 | 17 |
| Selling and marketing | 0 | 1 | 5 |

P1 gaps, in suggested build order (updated 2026-10-13 with the owner's answers below): new-order alerts by email, pre-orders, district and area at checkout with delivery fee by area, internal notes and status history, cancel and return with restock, Steadfast booking and tracking, cash collection from Steadfast, shop settings page, order SMS to the customer, manual order entry.

## Admin feature plan coverage

Every feature in `docs/ADMIN_FEATURE_PLAN.md` (1 to 18) and every unbuilt item in the `QUICK_STATUS.md` backlog appears in the tables below; none is built yet. The plan's groundwork steps G1 (order logic into services), G2 (public order view) and G3 (who did it) are internal changes with no screen of their own: they get built together with the first feature that needs them (features 2, 3, 10, 13, 14, 15 and 17).

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
| 13 | Second admin and roles | Admin, P3 |
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
| Order confirmation and order tracking by number and phone | Have | | | Shows status only, no courier tracking. |
| Policy pages (returns, delivery, privacy, terms) | Have | | | Wording still needs your real terms (see `QUICK_STATUS.md`). |
| SEO, share cards, sitemap | Have | | | |
| **District and area at checkout** | Built, in review | P1 | 5 | District dropdown with a Dhaka city or suburbs choice. Pull requests coovi-api#14, coovi-admin#16, coovi-storefront#15 (2026-10-13). |
| **Delivery fee by area** | Built, in review | P1 | 5 | Inside Dhaka city and outside Dhaka (suburbs included); placeholder fees 70 and 130 until the owner sets real ones. Same pull requests. |
| **Order confirmation SMS to the customer** | Missing | P1 | New | Customers expect an SMS with the order number; it also cuts "did my order go through?" calls. Needs an SMS provider account (for example SSL Wireless, BulkSMSBD). |
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
| **New-order alerts** to you | Missing | P1 | 1 | Nothing tells you an order arrived. Owner chose WhatsApp or email: email first (free, simple); WhatsApp needs a WhatsApp Business API account and approved message templates, so it comes later. |
| **Manual order entry** | Missing | P1 | 14 | Many orders arrive by Facebook message or phone; today they cannot go into the system, so stock and reports are wrong. |
| **Internal notes and status history** | Built, awaiting merge | P1 | 3 | Private notes, status history and detail-edit history with who and when: coovi-api#16, coovi-admin#10. |
| **Courier booking and tracking number** (Steadfast, owner's choice) | Partial | P1 | 4 | Built 2026-10-13 (coovi-api#18, coovi-admin#12): "Book with Steadfast" on a Processing order saves the tracking code and courier status. Needs the Steadfast API keys on Render. Not built: automatic status updates (Steadfast webhook), so the admin presses "check" and still marks Shipped and Delivered. |
| **Cancel and return with restock** | Have (in review) | P1 | 2 | `Returned` status for parcels refused at the door, with reason and restock (coovi-api#17, coovi-admin#11). No returns after delivery (owner decision). Customer-requested cancellation is still P3. |
| **Pre-orders** | Missing | P1 | New | Owner's rule: sell from stock when the saree is in stock; when it is not, take a pre-order that ships in at least 15 days. Needs a per-product "allow pre-order" switch and lead time, a clear "Pre-order, ships in about 15 days" label on the product page, cart and confirmation, pre-order orders marked in the admin, and stock that never goes below zero. Also answers what happens when two people order the last piece: the second becomes a pre-order instead of a failed confirmation. |
| **Cash collection from couriers** | Built, in review | P1 | New | Pull requests coovi-api#20, coovi-admin#13 (2026-10-13). Admin "Courier payments" page: delivered orders the courier has not paid for yet, payouts typed in from the courier's statement with its charge and return costs per parcel, and any shortfall. Manual entry; importing Steadfast's payment statements automatically can come with the courier booking work. |
| **Shop settings page** (WhatsApp number, support phone, announcement text, low-stock limit) | Built, in review | P1 | 6 | Pull requests coovi-api#22, coovi-admin#14, coovi-storefront#13 (2026-10-13). Delivery fees stay with the delivery-by-area work (owner decision 2026-10-13). |
| Dashboard and reports | Partial | P2 | 11 | Revenue chart and totals exist; no profit, best sellers or return rate. |
| Product cost price and profit | Missing | P2 | New | Needed for real profit numbers in reports. |
| Customers list and repeat buyers | Missing | P2 | 8 | |
| Fake-order check (block list, courier delivery-success check by phone) | Missing | P2 | 8 (block list), New (courier check) | |
| Real pagination and server search on orders | Partial | P2 | 12 | Search works but the admin downloads every order each time. |
| Staff accounts and roles | Missing | P3 | 13 | One shared login today. |
| Bulk actions (confirm or print many orders) | Missing | P3 | 15 | |
| Stock history log | Missing | P3 | 17 | |
| Homepage banner from the admin | Missing | P3 | 16 | |
| Product variants (same design, several colours) | Missing | P3 | 9b | Only if you stock repeats; owner is not sure yet, so it stays last. |
| Expenses and simple accounts | Missing | P3 | New | |
| Delete a product's photos from Cloudinary when the product is deleted | Missing | P3 | New | Open item from the photo upload work in `QUICK_STATUS.md`. |

## Selling and marketing

| Feature | State | Priority | Plan | Notes |
|---|---|---|---|---|
| Facebook Pixel and Conversions API | Missing | P2 | New | Most saree sales in Bangladesh come from Facebook and Instagram ads; without the pixel you cannot measure or optimise ads. Needs your Meta Business account. Moved from P1 to P2: owner will not run ads during development. |
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
