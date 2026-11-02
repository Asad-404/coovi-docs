# Plan: three small load fixes for the storefront

Written 2026-11-01. This is a plan only; no app code has changed. Measured on the live site, https://coovi-storefront.vercel.app, with a test browser. Anything marked "estimate" is worked out rather than measured.

## Owner decisions, 2026-11-02

Built in coovi-storefront#51: issues A and B, including the sharper hero photos at about 70 to 170 KB more on desktop. Issue C stays as it is, and prefetching should be measured again now that page caching is live.

## Summary

| Issue | What shoppers notice | Priority | Recommendation |
| --- | --- | --- | --- |
| A. Hover photos download on phones | Nothing today. Slower scrolling and more mobile data once products have 2 or more photos | Medium | Do now, before new photos go up |
| B. Desktop hero photos are slightly soft | Slightly soft photos on many laptops | Low to medium | Do now, together with A |
| C. Link prefetching | Pages open quickly; no visible problem | None for now | Change nothing, and measure again after page caching ships |

A and B are one-line changes that fit in one small pull request.

## A. Hover photos download on phones

**What it is.** On a computer, moving the mouse over a product card fades in the product's second photo. Phones have no mouse, so shoppers there never see that photo, but the phone still downloads it as the card nears the screen.

**Why it matters.** It uses a shopper's mobile data on a photo they cannot see, and it competes with the photos they are about to look at.

**Now and later.**

- Now: it costs nothing, because none of the 6 live products has a second photo.
- Later: publishing now needs at least 3 photos, so this starts as soon as products get new photos.
- Estimated cost on a home page with 12 cards, if the shopper scrolls through all of them:
  - About 240 KB on a typical phone, at about 20 KB per photo. Today's photos measure 17 to 26 KB at this size.
  - About 480 KB on a sharper phone, at about 40 KB per photo.
  - For comparison, the whole home page is about 820 KB on a phone today.
- On the slow connection used for testing (1.6 Mbps), 240 KB is about 1.2 seconds of extra downloading (estimate).

**The change.** One file, `components/ProductCard.tsx`, line 54. The second photo stays hidden unless the device has a mouse:

```tsx
className="hidden object-cover opacity-0 transition-opacity duration-500 pointer-fine:block group-hover/image:opacity-100"
```

Also update the comment on line 47 to say the second photo only loads on devices with a mouse. The second photo must stay lazy-loaded, as it is today.

I suggest `pointer-fine:block` rather than `md:pointer-fine:block`. Adding `md:` would also remove the hover photo for someone using a mouse in a narrow window, and that saves no phone data.

**What I checked.**

- **Hidden photos are not downloaded.** I tested this rule in Chrome on a small test page, not on the real card. On phone (375 px) and tablet (820 px) touch settings, the hidden photo was never requested, even after scrolling to it. A normal lazy photo on the same page was requested.
- **The desktop hover still works.** With a mouse, the photo downloaded before any hover and faded in smoothly: about halfway at 150 ms and fully visible by 850 ms.
- **Phones never show this photo today.** Tailwind only applies this hover effect on devices that can hover, so no phone shopper loses anything.
- **The layout does not change.** The photo sits on top of the first one and takes up no space of its own.
- **Other pages benefit too.** `/saree`, `/sale` and the 3 related products on product pages all use this same card. The eager loading on the first 3 cards of `/saree` and `/sale` only applies to the first photo.
- **Not tested:** Safari and Firefox. I expect the same result. If one of them did download the photo, that would be no worse than today.

**How to verify.**

- Run `pnpm lint`, `pnpm typecheck`, `pnpm test` and `pnpm build` in `coovi-storefront`.
- Manual check for the owner. It needs at least one live product with 2 or more photos:
  1. Open the home page in desktop Chrome and hover over that product's card. The second photo should fade in.
  2. Open DevTools, turn on the phone view, open the Network tab and filter by Img. Reload and scroll down. That product's second photo should not appear in the list.

## B. Desktop hero photos are slightly soft

**What it is.** The tall photo panels at the top of the home page tell the browser how wide each photo will be, so it can download the right size. That figure is too small on desktop, so many laptops download a photo smaller than it is drawn and stretch it.

**Why it matters.** These are the first and largest photos a desktop shopper sees, and sarees sell on fabric detail. The softness is slight, and phones are not affected.

**Now and later.** The problem exists today for desktop shoppers, and it will not get worse.

**Why the current number is wrong.** The panels are tall and narrow, and each 3:4 photo is scaled to fill the panel's height, with the sides cropped off. So height decides the size needed, not panel width:

- On desktop the panel is at least 600 px tall, so the photo is drawn 600 x 3/4 = 450 px wide. The panel itself is only about 271 px wide at a 1440 px screen.
- The code asks for 22% of the screen width, which is 317 px at that screen. The browser picks the 384 px file and stretches it to 450 px.
- Between about 1025 and 1163 px wide, it picks the 256 px file, which is noticeably softer.

| Layout | Strip height | Photo width needed | Value to use |
| --- | --- | --- | --- |
| Phone, under 640 px | 210 px | 158 px, or the panel width on wider phones | `45vw` (keep it) |
| Tablet, 640 to 1023 px | 320 px | 240 px, rising to 360 px | `36vw` |
| Desktop, 1024 px and up | at least 600 px | 450 px or more | `450px` |

**The change.** One file, `components/HomeHero.tsx`, line 93:

```tsx
// Photos fill the strip's height, so on desktop 600px tall x 3/4 = 450px wide, whatever the panel's width
sizes="(min-width: 1024px) 450px, (min-width: 640px) 36vw, 45vw"
```

This also fixes a small mismatch: the old rule treated a screen exactly 1024 px wide as a tablet, although the page shows the desktop layout there. `next.config.ts` does not need changing, and the layout stays as it is.

**Download cost for all 3 hero photos.** File sizes are measured on the 3 live hero photos. Which file each screen picks is worked out from the browser's rules.

| Screen | Today | After | Change |
| --- | --- | --- | --- |
| Phone, any common size | 384 or 640 | same | None |
| Tablet 768 px, sharp screen | 750 | 640 | About 40 KB less |
| Laptop 1100 px | 256 | 640 | About 92 KB more |
| Laptop 1280 to 1440 px | 384 | 640 | About 70 KB more |
| Desktop 1920 px | 640 | 640 | None |
| 1440 px Retina-style screen | 640 | 1080 | About 170 KB more |

The desktop home page is about 880 KB today, so the extra is about 8% to 20%, on screens that are usually on faster connections. If the Retina cost ever matters, `400px` instead of `450px` would pick a smaller file on those screens with almost no visible loss.

**Effect on the rest of the page.**

- **Skeleton:** no change. It uses grey blocks and does not load these photos.
- **Layout shift:** none, because the panels have a fixed shape.
- **Largest photo timing (LCP) on phones:** no change, because they get the same files.
- **LCP on desktop:** the hero photo is the page's largest element. In my test it finished loading at 753 ms and first appeared at 860 ms, so there is a little room. Estimate: no change to about 100 ms later on a fast connection.
- **Vercel image quota:** at most a few new resized versions out of the 5,000 allowed per month.

**How to verify.**

- Run `pnpm lint`, `pnpm typecheck`, `pnpm test` and `pnpm build` in `coovi-storefront`.
- Manual check for the owner, after deploying:
  1. Open the home page on a laptop and compare the hero photos with how they look today. Fabric detail should look crisper.
  2. On a phone, the hero should look exactly the same.

## C. Link prefetching

**What it is.** When a link comes into view, the site quietly fetches a small part of that page in advance, so the page responds as soon as a shopper taps the link.

**What it buys.** Tapping a link changes the screen at once. On a slow connection, shoppers would otherwise wait for a server round trip after each tap with nothing changing. This is the feature that makes the shop feel quick, and it matters most on phones.

**What it costs.** I measured a home page scrolled from top to bottom:

| Measure | Result |
| --- | --- |
| Requests | 22 to 25 |
| Data | 29 to 35 KB, about 4% of the page |
| Server calls (MISS) | 7 to 9: `/`, `/saree`, `/sale` and product links. Each runs the server |
| From the Vercel cache | 15: track order, about, contact and the 4 policy pages |

**The cached pages are not quite free.** Their cache status was HIT on one run and STALE on another. The shop header fetches shop settings with a 60-second refresh (`CACHE_SECONDS` in `lib/api.ts`), and that seems to make these otherwise fixed pages refresh too. A STALE reply still arrives instantly, then triggers one refresh in the background. On a quiet shop, one shopper reaching the footer could trigger up to about 7 refreshes. This is my reading of the response headers, not something Vercel confirmed.

**Vercel Hobby limits.** From Vercel's docs (page dated 2026-09-14), per month:

- 1,000,000 CDN requests
- 1,000,000 function invocations
- 4 hours of active CPU
- 5,000 image transformations

Going over usually means waiting up to 30 days to use that feature again. Estimates for a first-time visitor who scrolls the whole home page:

| Limit | Use per visit | Visits per month before reaching it |
| --- | --- | --- |
| CDN requests | About 66 | About 15,000, or 500 a day |
| Function invocations | About 17 at worst | About 59,000, or 2,000 a day |

I could not estimate active CPU, and real traffic is unknown. The Usage page in the Vercel dashboard shows both.

**Would turning off the footer links help?** Turning off prefetch on the 4 policy links in `components/Footer.tsx` (lines 17 to 20) would save 8 requests, about 15 KB and up to 4 background refreshes, and only for shoppers who reach the footer. CDN capacity would go from about 15,000 to about 17,000 visits a month (estimate). In return, those pages would be slower to respond when tapped. That is a small gain, so it is not worth doing now.

**Recommendation: change nothing now.** Page caching is about to change these numbers, so any tuning now could be wasted:

- `docs/PLAN_PAGE_CACHING.md` is being written in another session, and I have not read it. If it makes the home and product pages cached, most of the 7 to 9 server calls should become cache hits.
- **Prefetch data may go up.** Next.js fetches a cached page in full, rather than just its outline. A full product page is about 6.5 KB, so 12 product links could add about 80 KB per scrolled home page on top of today's 29 to 35 KB, and more requests (estimate). In return, product pages would open almost instantly, which is probably a good trade.
- **Suggestion for that plan:** look at the header's 60-second settings refresh, because it seems to be what keeps the policy pages refreshing.

**How to verify.** There is no code to verify. After page caching ships, repeat this measurement of the home page. Revisit this decision if either of these happens (my judgement, not hard limits):

- A scrolled home page on a phone prefetches more than about 150 KB.
- The Vercel Usage page shows CDN requests or function invocations above about 70% of the monthly limit.

The first step then would be the footer change above.

**Related.** Vercel's Hobby plan is for non-commercial use only, which `docs/GO_LIVE_CHECKLIST.md` already lists as item 8. Moving to a paid plan would change these limits. I did not check the paid plan's limits.

## Recommended order

1. **Now:** make A and B in one small storefront pull request. A should be live before products get new photos. B is cheap and improves the desktop first impression.
2. **Owner check:** after adding photos to the first product, run A's manual check. Run B's manual check after deploying.
3. **Wait:** leave C alone until page caching has shipped, then repeat the measurement.

## Decisions for the owner

1. Is about 70 to 170 KB more on desktop acceptable for sharper hero photos? I recommend yes.
2. Do you agree to leave link prefetching alone for now? I recommend yes.
