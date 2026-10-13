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
| Running orders (admin) | 4 | 3 | 16 |
| Selling and marketing | 0 | 1 | 5 |

P1 gaps, in suggested build order: new-order alerts, manual order entry, district and area at checkout with delivery fee by area, internal notes and status history, courier booking and tracking, order SMS to the customer, cancel and return with restock, shop settings page, Facebook Pixel, cash collection from couriers.

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
| **District and area at checkout** | Missing | P1 | 5 | Address is one free-text box. Couriers and area fees need district (and Dhaka inside or outside) as a choice. |
| **Delivery fee by area** | Missing | P1 | 5 | One flat fee for the whole country today. |
| **Order confirmation SMS to the customer** | Missing | P1 | New | Customers expect an SMS with the order number; it also cuts "did my order go through?" calls. Needs an SMS provider account (for example SSL Wireless, BulkSMSBD). |
| WhatsApp and Messenger chat button | Partial | P1 | | WhatsApp link exists with the placeholder number; no Messenger. |
| Contact form | Partial | P2 | | Contact page has a `mailto:support@coovi.com` link; that address only works once you own the domain. |
| Product details: fabric, colour, length, blouse piece, work | Partial | P2 | 9a | Only `size` exists. Saree buyers filter and decide on fabric and colour. |
| Categories and collections (Jamdani, Katan, Silk, Cotton, occasion) | Missing | P2 | 7 | Everything is "Saree". |
| Filter by price, colour, fabric | Missing | P2 | 9a | Sort only. |
| Bengali language | Partial | P2 | | Bengali product names show where set; menus, checkout and policies are English only. |
| Courier tracking link for the customer | Missing | P2 | 4 | |
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
| **New-order alerts** (Telegram, email or SMS to you) | Missing | P1 | 1 | Nothing tells you an order arrived. |
| **Manual order entry** | Missing | P1 | 14 | Many orders arrive by Facebook message or phone; today they cannot go into the system, so stock and reports are wrong. |
| **Internal notes and status history** | Missing | P1 | 3 | No place to write "called, will pay on Friday" and no record of who changed what. |
| **Courier booking and tracking number** (Steadfast, Pathao, RedX) | Missing | P1 | 4 | Plan covers typing in the tracking number; booking the parcel through the courier's API is New. |
| **Cancel and return with restock** | Partial | P1 | 2 | Cancel works before shipping. A parcel the customer refuses at the door, or a return after delivery, has no status and no restock. |
| **Cash collection from couriers** | Missing | P1 | New | Track which delivered parcels the courier has paid you for, their charge, and return costs. This is where COD shops lose money. |
| **Shop settings page** (fee, WhatsApp number, announcement text) | Missing | P1 | 6 | Today these need a code change or a Render variable. |
| Dashboard and reports | Partial | P2 | 11 | Revenue chart and totals exist; no profit, best sellers or return rate. |
| Product cost price and profit | Missing | P2 | New | Needed for real profit numbers in reports. |
| Customers list and repeat buyers | Missing | P2 | 8 | |
| Fake-order check (block list, courier delivery-success check by phone) | Missing | P2 | 8 (block list), New (courier check) | |
| Real pagination and server search on orders | Partial | P2 | 12 | Search works but the admin downloads every order each time. |
| Staff accounts and roles | Missing | P3 | 13 | One shared login today. |
| Bulk actions (confirm or print many orders) | Missing | P3 | 15 | |
| Stock history log | Missing | P3 | 17 | |
| Homepage banner from the admin | Missing | P3 | 16 | |
| Product variants (same design, several colours) | Missing | P3 | 9b | Only if you stock repeats. |
| Expenses and simple accounts | Missing | P3 | New | |
| Delete a product's photos from Cloudinary when the product is deleted | Missing | P3 | New | Open item from the photo upload work in `QUICK_STATUS.md`. |

## Selling and marketing

| Feature | State | Priority | Plan | Notes |
|---|---|---|---|---|
| **Facebook Pixel and Conversions API** | Missing | P1 | New | Most saree sales in Bangladesh come from Facebook and Instagram ads; without the pixel you cannot measure or optimise ads. Needs your Meta Business account. |
| Facebook and Instagram product catalogue feed | Missing | P2 | New | Lets you tag products in posts and run catalogue ads. |
| Visitor analytics (Google Analytics or Vercel Analytics) | Missing | P2 | New | |
| Google Search Console and Merchant Center | Partial | P2 | | Product structured data exists; sitemap not yet submitted (needs the real domain). |
| Abandoned-cart follow-up | Missing | P3 | New | Needs the phone before checkout ends, so it is a later step. |
| Newsletter or SMS marketing list | Missing | P3 | New | Needs customer consent. |

## Decisions only you can make

These change what gets built, so they are worth answering before the P1 work starts (some repeat the plan's own open questions):

1. Where do most orders come from today: the website, Facebook messages, or phone? This decides how early manual order entry is needed.
2. Which courier will you use first? This decides which booking API to build.
3. Alerts to you: Telegram, email or SMS?
4. Is each saree one of a kind, or do you restock the same design? This decides stock reservation and variants.
5. Do you accept returns after delivery?
6. Will you run Facebook ads at launch?
