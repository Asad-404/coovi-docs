# Plan: serve home and product pages from cache

Written 2026-11-01 for storefront commit `0e4211a` (Next.js 16.3.8). Corrected 2026-11-02 with what the live site showed after PRs 1 to 3 merged. The rest of this file is the plan as written, so it describes the old behaviour as "today".

## Result on the live site (checked 2026-11-02)

| Pull request | State |
|---|---|
| PR 1, cache the home page | Merged, coovi-storefront#45 |
| PR 2, wake the API before building | Merged, coovi-storefront#46. The script's line in the Vercel build log is not confirmed yet; only the owner can see it |
| PR 3, cache product pages | Merged, coovi-storefront#47 |
| PR 4, refresh settings every 5 minutes | Open, coovi-storefront#48, waiting on the owner's decision |

**What worked:** both pages are served from the cache (`X-Vercel-Cache: HIT`, no `no-store`), and the old `/?search=` link redirects as planned.

**What this plan got wrong:**

1. **Cached pages do not arrive complete.** The saved home and product pages still start with their `loading.tsx` skeleton, with the real content hidden behind it (`<!--$?-->` and `hidden id="S:0"` in the HTML: 97 skeleton blocks on `/`, 52 on a product page, 0 on `/about`, which has no `loading.tsx`). So caching did not solve the photo wait.
2. **Missing products still return 200, not 404.** `/products/no-such-saree` returns 200 with "Product not found" and `noindex`. Next.js returns 200 for streamed pages (`loading.md`, "Status Codes"), which is the likely cause because these pages are streamed through `loading.tsx`. Search engines should not index it, and shoppers see the right message.

**Likely fix for both, not tested:** remove `loading.tsx` from the home and product routes. The cost is no skeleton when tapping through to those pages. This belongs in `docs/PLAN_SKELETON_PHOTO_WAIT.md`, which has not been delivered yet.

**Owner decision 2026-11-02:** a browser call to the API for live price and stock, with a skeleton, was built in coovi-storefront#49 and closed without merging. Product pages keep showing the saved price and stock.

## In short

Before this work, every visit to the home page or a product page made Vercel's server in Washington build the page again. The plan was to keep a ready-made copy and hand it out straight away, then refresh that copy in the background. Next.js calls this ISR (Incremental Static Regeneration): a saved page that renews itself after a set time.

- **Home and product pages** get cached. `/saree` and `/sale` stay as they are.
- **Size:** 3 small pull requests, plus 1 optional. No API or admin changes.
- **Main cost:** a shopper can sometimes see an older price or stock count. Checkout still uses the API's real numbers.

## How sure each statement is

| Label | Meaning |
|---|---|
| **Tested** | I ran `next build` on a throwaway copy of the storefront against a fake API that I could make answer, sleep, hang or refuse. Nothing was deployed. |
| **Docs or source** | Read in the Next.js 16.3.8 guides or code, or in Vercel's docs, but not run. Dev servers and `next start` are owner-run, so runtime behaviour is unproven until the preview checks below. |
| **Estimate** | My arithmetic from the measurements, not a measurement. |

## What the build showed

| Situation | Result | Label |
|---|---|---|
| Today's code | `/`, `/products/[slug]`, `/saree`, `/sale` are dynamic (built per visit) | Tested |
| After the changes below | `/` is cached with a 1 minute refresh; `/products/[slug]` is cached | Tested |
| API refuses connections, home keeps today's error handling | Build passes and "Could not load products" is saved into the home page | Tested |
| API refuses connections, home always throws | **Build fails** on `/` | Tested |
| API refuses connections, home throws except during a build | Build passes with the fallback page | Tested |
| API refuses connections, any page | The placeholder WhatsApp number and default announcement are saved into `/`, `/about` and `/contact` (the three I checked) | Tested |
| API asleep for 50 s | Build passes, 86 s instead of 52 s, all 6 product pages built | Tested |
| API asleep for 90 s | Build passes, 136 s, home has real products, but **0 product pages built** (the product list request gave up at 60 s) | Tested |
| API never answers | **Build fails** after about 3 minutes (3 tries of 60 s each); the live site stays as it was | Tested |

In the last row, `/about` and other unchanged pages timed out as well, so today's build very probably has the same limit. I did not run that case on unchanged code, but `docs/PLAN_HEADER_BLANK_SCREEN.md` reports the same failure from the settings call.

## Pull requests, in order

Each PR runs `pnpm lint`, `pnpm typecheck`, `pnpm test` and `pnpm coverage`. Then delete `.next` and run `pnpm build`, and read the route table it prints. `.next` must go first: a leftover copy less than 60 seconds old is reused and the API is never called, which gave me two false results.

### PR 1: cache the home page

1. `next.config.ts`: add the old search link to `redirects()`, next to `/shop`. Query values pass through on their own, so `?search=` stays in the address.
   ```ts
   { source: "/", has: [{ type: "query", key: "search", value: ".+" }], destination: "/saree", permanent: false }
   ```
   `.+` keeps an empty `/?search=` on the home page, as now. `permanent: false` matches today's temporary redirect, and browsers do not remember it, which keeps rollback clean.
2. `lib/api.ts`: add a small helper, `isBuildPhase()`, that checks `process.env.NEXT_PHASE === "phase-production-build"`. Add its test to `lib/api.test.ts`, since `lib/` must stay at full coverage.
3. `app/(home)/page.tsx`: remove `props.searchParams` and the `redirect` import (lines 2 and 41-46). Change the `catch` at lines 49-53 to rethrow unless `isBuildPhase()` is true.

Do not add `export const revalidate`. The page's own fetch already sets 1 minute from `CACHE_SECONDS` (tested), and a second number would have to be kept in step by hand.

**Verify:** the route table shows `○ /` with `1m`. Then on the Vercel preview:

```bash
curl -sI "$URL/" | grep -iE "x-vercel-cache|cache-control|x-vercel-id"   # run twice: the second should say HIT, with no no-store
curl -sI "$URL/?search=red%20silk" | grep -iE "^HTTP|^location"          # 307 to /saree?search=red%20silk
curl -sI "$URL/?search=" | grep -i "^HTTP"                               # 200, stays on home
```

Vercel may protect preview links with a login, and curl then gets a 401. If so, the owner either creates a shareable link or runs these checks straight after merging.

### PR 2: wake the API before building

1. Add `scripts/wake-api.mjs`, about 15 lines. It only runs when `VERCEL` is set, so local builds skip it. It calls `${NEXT_PUBLIC_API_URL}/products?limit=1`, retries for up to 90 seconds, and **always exits successfully**.
2. `package.json`: change `build` to `node scripts/wake-api.mjs && next build`.

This keeps the sleeping-API cases above from producing a thin build. A free uptime monitor (`docs/GO_LIVE_CHECKLIST.md` item 4) would make this step mostly unnecessary. I would still add it, because the monitor can stop without anyone noticing, and it costs only a few lines.

**Verify:** the Vercel build log shows the script ran. Deploy once after the API has been quiet for 20 minutes and confirm the build finishes.

### PR 3: cache product pages

`app/products/[slug]/page.tsx`: add the function below and import `getAllProducts`.

```ts
export async function generateStaticParams() {
  try {
    const products = await getAllProducts();
    return products.map((product) => ({ slug: product.slug }));
  } catch {
    return [];
  }
}
```

This differs from the plain empty list first suggested. An empty list also enables caching (tested), but each deploy starts with an empty page cache on Vercel (Vercel docs), so each product's first visitor would then take the slowest path (see trap 3). Listing the real products builds them in advance, and the `catch` falls back to the empty list if the API is unreachable (tested). Products added after a deploy are still built on their first visit.

**Verify:** the route table lists `● /products/...` with `1m` for each product. With the API unreachable it shows `● /products/[slug]`. On the preview:

```bash
curl -sI "$URL/products/<real-slug>" | grep -iE "x-vercel-cache|cache-control|x-vercel-id"   # run twice: HIT
curl -sI "$URL/products/no-such-saree" | grep -i "^HTTP"                                     # still 200 on the live site, see "Result" above
```

### PR 4 (optional): refresh shop settings less often

`lib/api.ts`: give `getShopSettings` its own 5 minute refresh instead of `CACHE_SECONDS`, and update its tests. See "Vercel Hobby usage" for why.

**Verify:** the route table shows `5m` for `/about` and the other fixed pages. `/delivery-policy` stays at `1m` because it also fetches the delivery fee.

### After merging

Keep the "Known notes" soft-404 line in `QUICK_STATUS.md`, because the 404 check above did not pass. Repeat the home page measurement from `docs/PLAN_SMALL_LOAD_FIXES.md`.

## `/saree` and `/sale` stay dynamic

- Their content depends on the search word, sort order and page number in the address, and so do their search-engine tags. Next.js cannot save one copy for all of those.
- Caching just the plain `/saree` would mean moving the list into the browser. The browser would then call the sleeping API directly, with a 30 second limit, which is worse than today.
- Their product data already has the 1 minute cache, and the product pages they lead to will be cached.

So they keep their current speed. Reconsider only if measurements show they are hurting sales.

## The traps

### 1. A saved error page (home)

| Case | What happens | Label |
|---|---|---|
| Refresh, API fails, today's code | The error is caught, so "Could not load products" **replaces the good page** for everyone until a refresh succeeds | Docs or source |
| Refresh, API fails, after PR 1 | The render fails, and Vercel keeps the last good page and retries about 30 seconds later | Docs or source |
| Build, API fails, after PR 1 | The build passes with the "Could not load products" page. The first good refresh replaces it, and every visit after the first minute tries again | Tested (build), Docs or source (replacing) |
| API returns an empty list | Saved as "New sarees are being added". This is correct, since it is a real answer | Docs or source |

Why keep the fallback instead of letting the build fail? A failed build is safe for shoppers, but my own checks and any build without the API running would fail too. With PR 2, the fallback should only appear when the API is really down, and then nobody can order anyway.

`isBuildPhase()` reads a setting Next.js uses internally. If an upgrade removes it, builds fail loudly rather than saving an error page, which is the safe direction.

The product page already rethrows real errors, so it needs no change here.

**Default settings can be saved too.** `getShopSettings` never throws, because the header is on every page. A failed settings call therefore looks like a success, and the defaults get saved, including the placeholder WhatsApp number. This already happens today on the fixed pages; caching adds home and product pages to the list.

| Case | What gets saved | Label |
|---|---|---|
| Build, API down | Placeholder number and default announcement, until the first good refresh after a visit | Tested |
| Fixed page (about, contact), refresh, settings call fails | The defaults **replace the good copy**, because that page has no other API call to fail | Docs or source |
| Home or product, refresh, whole API failing | Nothing. The main product call fails too, so the good page is kept | Docs or source |
| Home or product, refresh, only settings fails | The defaults, until the next good refresh. The delivery fee and related products on product pages behave the same way | Docs or source |

A sleeping API is mostly not the cause: when refreshing an old copy, Next ignores the 60 second timeout and waits. The risk is the API returning errors or being unreachable.

I would not make `getShopSettings` throw, because that would turn a small blemish into an error page on pages that are not cached. The cheap protection is to **set `NEXT_PUBLIC_WHATSAPP_NUMBER` in Vercel once the real number is ready**. Then the default number is the real one, and only the announcement can be out of date.

### 2. Building while the API sleeps

The table at the top covers this. Note that `SERVER_TIMEOUT_MS` and Next's build limit per page are both 60 seconds, so a slow request can use up a whole attempt. Next retries twice. PR 2 is the fix. I do not recommend raising the build limit, because it would not help the product list request, which gives up at 60 seconds on its own.

### 3. Unknown, deleted and draft products

- **The soft 404 stays.** This plan expected a true 404 because cached pages would not be streamed, but the live site still streams them through `loading.tsx` and returns 200 with `noindex`. Tested on the live site 2026-11-02.
- **"Not found" results get saved too.** Vercel treats 404 as a valid result (Vercel docs). If someone opens a product's address before it is published, the first visitor after publishing can still see "not found". That visit triggers the refresh, and the next visitor sees the product. To check a new product yourself, open it, wait a few seconds and reload.
- **Junk addresses** each cost one server run and one API call, as they do today, plus a small saved page.
- **How long an unpublished or deleted product stays visible:**
  - Busy shop: about 2 minutes at most (data up to 60 s old, in a page kept for 60 s). Estimate.
  - Quiet shop: until one more visit has happened. The first visitor after a quiet spell gets the old copy however old it is, and that visit triggers the refresh. The build table lists an expiry of 1 year.
  - It can't be sold either way: the API refuses unpublished products at checkout (`orderPricing.ts:40`).
- **First visit to a product not yet saved, with the API asleep.** This is the one case that gets worse. The route is "blocking" (seen in the build output), and a page's first-ever build waits for everything, so the browser shows a white page with no skeleton for up to 60 seconds. Neither a saved copy of the data nor the header fix in `docs/PLAN_HEADER_BLANK_SCREEN.md` helps: the first build waits for fresh data even when an old copy exists (`patch-fetch.js`), and it waits for everything inside Suspense too. If the API never answers, the shopper probably gets a plain error page rather than `app/error.tsx`. Docs or source, so check it on the preview: 20 minutes after API traffic stops, curl a product added after the deploy. PR 3 limits this to products added since the last deploy, and an uptime monitor would remove most of what remains.

### 4. Old stock and price

"Up to 60 seconds" is only true for a busy shop. Three things add to it:

1. A saved page can use data that was already up to 60 s old, so about 2 minutes in all.
2. On a quiet shop, the first visitor gets the old copy, as above. Today's data cache already behaves this way, so this is not new.
3. **This one is new:** cached pages are kept in the shopper's open browser tab for 5 minutes after being prefetched (`staleTimes.md`).

The API stays in charge. It recalculates price and stock when the order is placed, and refuses an order it cannot fill.

**One existing gap, outside this plan.** The cart keeps the price from when the item was added, and the button says "Place order for ৳X" using that price. If the price has since gone up, the API charges the new price without warning, and the shopper sees it only on the confirmation page. Caching makes this slightly more likely but did not create it. I suggest a small follow-up: compare the totals and warn the shopper.

### 5. Anything else that would keep pages dynamic

None found (Tested: the route table shows both as cached).

- `cookies()` and `headers()` appear only in `order-confirmation` and `track-order/[orderNumber]`.
- `useSearchParams` appears only in `ProductFilters` and `LoadMoreButton`, which are used on the listing pages.
- The only `no-store` fetch is the order lookup.
- There is no `proxy.ts`, and the security policy in `next.config.ts` uses no per-visit codes.
- The cart lives in the browser, so nothing personal gets saved in a cached page.

### 6. Instant refresh when the admin edits a product

**Recommendation: not now.** The API would call a new secret-protected storefront address after every product edit, so that the next visitor gets fresh content.

- **For:** edits appear straight away, including on a quiet shop, which also closes the gap in trap 4.
- **Against:** it adds a new endpoint and a shared secret across two repos, for a gap of about a minute on most edits. Stock also changes with every order, so those would need calls too, and there would be a new failure to handle when Vercel cannot be reached.
- **Revisit** if you often need edits to show immediately, or if Vercel usage forces a much longer refresh time. On-demand refresh plus a long interval is the pairing Vercel recommends in that case.

## Prefetching and Vercel Hobby usage

These two findings came from `docs/PLAN_SMALL_LOAD_FIXES.md`. I checked both, and both hold.

### Prefetching (loading linked pages in advance)

- **Holds:** Next.js prefetches cached pages in full (`prefetching.md`). I measured live product page data at 6.5 KB compressed.
- **Refined:** the home page shows at most 12 different products, and the two home sections link to the same ones. So the extra data is about **40 KB today with 6 products, about 80 KB at 12 or more** (estimate). Some of today's 29 to 35 KB of prefetching is replaced, so the true increase should be smaller. Photos are not prefetched.
- **In return:** tapped product pages open almost instantly. I recommend accepting this, and revisiting if a scrolled home page prefetches more than about 150 KB, the limit that plan sets.

### The 60-second refresh

- **Holds, and is now firmer:** the build table shows `/about`, `/contact`, `/cart`, `/checkout` and more at `1m`. Even `/delivery-policy`, which asks for 1 hour, shows `1m`. Next uses the lowest time on a page (Next docs), and the header's settings fetch is on every page.
- **What it means for home and product pages:** a refresh only runs when someone visits after the minute is up, and each page refreshes at most once a minute. A refresh of a page that has not changed uses no saved-page storage (Vercel docs). The refresh also wakes the sleeping API for the shoppers who follow.
- Home and product pages would stay at 1 minute anyway, because of their own data. PR 4 only helps the fixed pages.

### Monthly Hobby limits (estimates, per first-time visitor who scrolls the home page)

| Limit | Today (from that plan) | After caching, worst case | Visits per month before the limit |
|---|---|---|---|
| CDN requests (1,000,000) | About 66 | About 80 to 90 | About 11,000 to 12,500, or about 400 a day |
| Function runs (1,000,000) | About 17 | About 23 | About 43,000 |
| Active CPU (4 hours) | Unknown | Unknown | Unknown, see below |

- The CDN row assumes up to 2 more requests per product link. With 6 products it is about 72 to 78 requests.
- The function row assumes prefetches trigger refreshes on Vercel, which I could not confirm. Next's own server does not do this for prefetches. Repeat visits and busy periods cost much less, because each page refreshes at most once a minute however many people visit.
- **Active CPU may be the real limit.** 4 hours is 14,400 CPU-seconds. If a page render uses 0.1 s, which is only a guess, the 23 runs above reach the limit at about 6,000 visits a month. Normal browsing would use less than this worst case, and busy periods save CPU compared with today, since cached views need no render.

Going over a limit usually means waiting up to 30 days, so check instead of guessing: look at the Vercel Usage page one week after shipping. If anything is above about 70% of its limit, first raise `CACHE_SECONDS` to 300. That is one line, but edits then take up to about 10 minutes on a busy shop. Vercel's Hobby plan is also non-commercial only (`docs/GO_LIVE_CHECKLIST.md` item 8), and moving off it changes these limits.

## Measured gains (2026-11-02)

Time to first byte, measured with curl once the page was warm. The plan's estimate of about 160 to 195 ms held:

| Page | Before | After |
|---|---|---|
| Home | 400 to 566 ms | About 150 to 215 ms |
| Product | 378 to 456 ms | About 133 to 150 ms |
| `/saree`, not cached, for comparison | 395 to 669 ms | About 365 to 440 ms |

- The first requests after a deploy or a quiet spell still took about 400 to 950 ms.

Phone on slow 4G (median of 3 runs, one product page, cache empty):

| Page | | First paint | LCP (main content shown) | Blocking | Downloaded |
|---|---|---|---|---|---|
| Home | Before | 2.57 s | 2.65 s | 995 ms | 783 KB |
| Home | After | 1.82 s | 2.52 s (2.36 to 3.07) | 201 ms | 472 KB |
| Product | Before | 2.08 s | 3.84 s | 717 ms | 760 KB |
| Product | After | 1.88 s | 2.46 s (2.45 to 2.61) | 567 ms | 449 KB |

- **The phone numbers are not from caching alone.** The Meta Pixel removal (#43), the main photo priority (#42) and the font change (#44) went live in the same period, and they account for the drop in downloaded data and most of the drop in blocking time.
- Layout shift stayed at 0 in all 6 runs.
- The home page's LCP barely moved because its photos still wait behind the skeleton. See "Result" above.

Not measured: tapped product links opening once prefetched, whether the slow 1.39 s sample has gone, and how these pages behave when the API is asleep.

This work does not speed up photos, `/saree`, `/sale`, or checkout's first call to a sleeping API.

## Rollback

No data or API changes are involved, so rollback is simple and each PR can be undone alone.

- **Fastest:** in the Vercel dashboard, use Instant Rollback to the previous deployment. Saved pages belong to each deployment, so nothing lingers.
- **Lasting:** revert the PR in `coovi-storefront`.
- Reverting PR 1 alone also restores the old search redirect.

## Relationship to other plans

- `docs/PLAN_SKELETON_PHOTO_WAIT.md`: **not** solved by this work, because cached pages still start with the skeleton. That plan should test removing `loading.tsx` from the home and product routes.
- `docs/PLAN_HEADER_BLANK_SCREEN.md`: changes the same header, and the two plans can merge in either order. They protect different pages: that plan covers `/saree`, `/sale` and the order pages, and this one covers home and products. Its fix does not touch `lib/`, so PR 4 here should not clash with it. Whichever ships second should re-check the route table, because cookies or headers in the header would make every page dynamic.
- `docs/PLAN_SMALL_LOAD_FIXES.md`: its prefetching numbers should be measured again after this ships.

## Decisions for the owner

Status 2026-11-02: decisions 1, 2, 3 and 6 are settled by merging PRs 1 to 3. Decision 4 is still open as coovi-storefront#48. Decisions 7, 8 and 9 are still the owner's to do. Decision 5 was never answered, so its recommendation (not now) stands. Before starting decision 9, check that keeping the API awake fits Render's free plan terms and monthly hours.

1. **Is a possibly older price or stock count acceptable on these pages?** About 2 minutes on a busy shop, and for the first visitor after a quiet spell, with checkout still correct. Recommendation: yes. Today's data cache already has the quiet-spell behaviour.
2. **Build known products in advance, or only on first visit?** Recommendation: in advance (PR 3 as written).
3. **Add the wake-up step to builds (PR 2)?** Recommendation: yes.
4. **Do PR 4, so shop settings refresh every 5 minutes?** A changed WhatsApp number or announcement would take up to about 10 minutes to show everywhere, in exchange for fewer background refreshes on fixed pages. Recommendation: yes, unless you edit the announcement at short notice.
5. **Instant refresh on admin edits?** Recommendation: not now.
6. **Accept up to about 80 KB more prefetching on a scrolled home page?** Recommendation: yes, and measure after shipping.
7. **Check the Vercel Usage page one week after shipping?** Only you can see it. Recommendation: yes. It also tells us which limit really matters.
8. **Set `NEXT_PUBLIC_WHATSAPP_NUMBER` in Vercel when the real number is ready, as well as saving it in the admin?** Recommendation: yes. It stops the placeholder number being saved into cached pages.
9. **Add a free uptime monitor on `/health`?** This is also decision 4 in `docs/PLAN_HEADER_BLANK_SCREEN.md`. Recommendation: yes. It removes most of the sleeping-API risks here.
