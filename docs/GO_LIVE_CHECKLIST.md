# Needed before going live

Last reviewed: 2026-11-12.

This is the short list of actions that still matter before Coovi accepts real orders. **You** means the owner must create an account, pay for a service or make a business decision. **Claude** means the change can be built in a pull request. **Both** means the owner supplies access or a decision first.

## Before accepting real orders

| Action | Why it matters | Owner |
|---|---|---|
| Create a separate `coovi-prod` Atlas database and user, then update Render's `MONGODB_URI`. | The live site still uses the development database, so test and customer data are not separated. | You |
| Set up backups: move Atlas to a tier with snapshots or choose a private nightly backup destination. | The free cluster does not provide automatic backups. | Both |
| Move off free commercial-hosting plans where required, especially Vercel Hobby and Render free. | Hosting terms, sleeping services and usage limits can interrupt a commercial shop. | You |
| Set the same random `STOREFRONT_API_KEY` on Render and Vercel, then redeploy. | Server-side storefront requests otherwise share the public rate limit. | You |
| Buy and connect the real domain; update `NEXT_PUBLIC_SITE_URL` and `CORS_ORIGINS`. | Canonicals, share links, sitemap and customer trust should use the permanent address. | Both |
| Replace development credentials with a new `JWT_SECRET`, production admin email and strong password. | Development credentials must not protect production. | You |
| Replace the WhatsApp placeholder, confirm delivery fees, add real photos and review policy terms. | Customers must see accurate contact details, fees, delivery promises and product information. | You |
| Set `NEXT_PUBLIC_WHATSAPP_NUMBER` in Vercel as well as the admin setting. | Cached or API-failure fallbacks must not show the placeholder number. | You |
| Check business registration, e-commerce and required customer-facing terms with an accountant or lawyer. | The checklist is not legal advice and Bangladesh requirements may change. | You |
| Complete the browser acceptance checks in `QUICK_STATUS.md`. | Tests do not cover real phones, live credentials, browser permissions or API sleep/wakeup. | Both |
| Create and test the Steadfast account if it will deliver launch orders. | Courier booking needs merchant credentials and a real parcel test. | Both |

## First weeks after launch

- Add error tracking to the API, storefront and admin after choosing a provider.
- Turn on GitHub Dependabot security alerts and security updates in all three app repositories.
- Decide whether the one-week order-phone cookie should be shorter on shared devices.
- Decide whether to add two-step admin login and whether customer SMS is worth the provider cost.
- Review Atlas access, CSV export retention and the process for deleting old customer data.
- Check Vercel Usage after a week of normal traffic and review the Render plan's sleep and usage limits.
- Add visitor analytics only if the owner wants it and the privacy wording is updated.

## Already done in code

Prices, stock, delivery fees, totals, status transitions and authorization are API-controlled. Production startup rejects weak secrets and localhost CORS; login, checkout and order lookup are rate limited; security headers and admin noindex are set; order numbers are hard to guess; email alerts, call confirmation, notes/history, returned-parcel restock, courier-payment recording, server-side order search, reports, customers, roles, draft publishing and phone-admin layouts are merged.

The Meta Pixel and other ad tracking are intentionally not used. The customer order SMS, automatic Steadfast updates, online payments, categories, product filters and other growth features remain optional backlog items, not launch blockers unless the owner changes priorities.
