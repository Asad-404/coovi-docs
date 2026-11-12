# COOVI Quick Status

Last updated: 2026-11-12. All dev servers are stopped; nothing is running.

Start here when resuming. The API contract is [API_ENDPOINTS.md](API_ENDPOINTS.md), business gaps are in [docs/FEATURE_GAPS.md](docs/FEATURE_GAPS.md), and launch actions are in [docs/GO_LIVE_CHECKLIST.md](docs/GO_LIVE_CHECKLIST.md).

## Waiting on the owner

1. **Production database:** create a separate `coovi-prod` database and user in Atlas, then point Render's `MONGODB_URI` at it. The live API still uses the development database.
2. **Production secrets:** create a new `JWT_SECRET`, production admin email and strong admin password, and save them in a password manager before changing Render.
3. **Real business details:** replace the WhatsApp placeholder `8801700000000`, confirm the inside/outside Dhaka fees (the live API returned 70 and 130 on 2026-11-01), add real product photos and review the policy wording. Set the real `NEXT_PUBLIC_WHATSAPP_NUMBER` in Vercel too, so cached fallbacks cannot show the placeholder.
4. **Hosting and domain:** review the paid hosting requirements, buy the real domain, connect it to Vercel and Render, then update `NEXT_PUBLIC_SITE_URL` and `CORS_ORIGINS`.
5. **Backups and legal setup:** choose an Atlas paid tier or a private nightly backup, and check Bangladesh registration and e-commerce requirements with an accountant or lawyer.
6. **Steadfast:** create the merchant account and add its Render API keys if courier booking and customer tracking are wanted at launch.
7. **Manual browser check:** complete the acceptance list below before taking real orders.

## Docs repository

The workspace root is the private `Asad-404/coovi-docs` repository on `master`. It tracks only these documents, `docs/` and `tools/`; the three app folders are ignored. Older planning documents remain available in Git history but are no longer part of the working documentation set.

## Live deployment

- API: <https://coovi-api.onrender.com> (Render; `/health` checks the database).
- Storefront: <https://coovi-storefront.vercel.app>.
- Admin: <https://coovi-admin.vercel.app>.
- Vercel environment: `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL` and `VITE_API_URL`.
- Render environment: `CORS_ORIGINS`, `STOREFRONT_API_KEY`, database and production secrets. The same random `STOREFRONT_API_KEY` must be set on Render and Vercel.
- The public site may still be indexed while it has the placeholder number and development data.

## Current product status

- Customer flow: browse `/saree` and `/sale`, product pages, cart, guest COD checkout, order confirmation and order tracking.
- Admin flow: products and drafts, photo upload, orders, manual orders, notes and history, statuses including refused-parcel `Returned`, delivery fees, courier payments, customers and block list, reports, roles, shop settings and CSV/print tools.
- Courier booking with Steadfast is built, but needs the owner's account and keys. Automatic courier status updates and the customer-facing tracking link are not built.
- Product pages keep cached price and stock; checkout rechecks current values. Home and product first-byte measurements after caching were about 150–215 ms and 133–150 ms respectively.
- No ads or ad pixels are planned. The seed data is stale; do not run the seed script against the live database.

## Browser acceptance still needed

These checks require a real browser, phone or live service and are not verified by tests alone:

- Checkout area radios, current-price change warning and one test order.
- Track Order with the correct phone and with a wrong phone.
- Order confirmation after status changes and during an API outage.
- Draft, publish and unpublish a product, including photo and share-image rules.
- Manual order district selection and delivery-fee preview.
- Steadfast booking and a tracking-status check, once the account exists.
- Phone-admin Call, WhatsApp, photo upload, keyboard Save bar and Print slip actions.
- API sleep/wakeup behavior and the first visit to a newly published product.
- Retry the storefront listing's “Try again” action when the API is unreachable.

## Remaining build backlog

Waiting on an owner account or decision: customer SMS, error tracking, Steadfast automatic updates, visitor analytics and the launch actions in [docs/GO_LIVE_CHECKLIST.md](docs/GO_LIVE_CHECKLIST.md).

Later, if the shop needs them: discount codes, bulk order actions, stock history, an admin-controlled homepage banner, product variants, reviews, back-in-stock requests, wishlist, customer accounts, online payment and Bengali copy.

## Policies and placeholders

The storefront has return, delivery, privacy and terms pages. Returns after delivery are not accepted; customers check the parcel before paying and refuse it when necessary. Add the owner's real delivery terms and any legally required wording before launch.

The remaining visible placeholders are the WhatsApp number, text-recreated logo and generic care-guide copy. Real admin credentials and production CORS values belong only in ignored `.env` files or hosting dashboards.

## Operational notes

- Cached home and product pages can show a briefly older price or stock value; checkout is authoritative.
- A new page can wait for the sleeping API for up to about 60 seconds. Retry a Vercel deploy if a build reports that a page took more than 60 seconds.
- Check Vercel Usage after the next week of normal traffic; only the owner can see the account limits.
- Next 16 may return HTTP 200 for a streamed `notFound()` page; product pages use `noindex` as mitigation.

## Manual resume commands

```bash
cd /d/Work/COOVI/coovi-api && pnpm dev
```

```bash
cd /d/Work/COOVI/coovi-storefront && pnpm dev
```

```bash
cd /d/Work/COOVI/coovi-admin && pnpm dev
```

```bash
curl http://localhost:5000/api/products
```
