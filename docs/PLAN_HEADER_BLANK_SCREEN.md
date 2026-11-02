# Plan: stop a sleeping API from blanking the storefront

Written 2026-11-01. A plan only; no app code has changed. Storefront `master` at `0e4211a`, Next.js 16.3.8.

## Owner decisions, 2026-11-02

Built in coovi-storefront#50.

1. Option (a) alone, keeping the 60-second timeout: **yes**.
2. Stand-in chat link goes to `/contact`: **yes**.
3. Layout shift: **keep the announcement on and to one line**, so it stays at 0. Turning it off, or text that wraps on a phone, brings the small shift described below.
4. Free uptime monitor: **not yet**. Render's free plan page does not mention pinging. It gives 750 hours a month per workspace, and running non-stop uses at most 744, so any other free service in that workspace would run the hours out and suspend all of them. It also says not to use free instances for production.

**Correction:** point 1 under "How this fits" is wrong for the home and product pages. They stream through `loading.tsx`, so their saved copies do have a pending boundary, and the stand-ins can appear briefly there. `/about` and `/contact` come out finished, as described.

## In plain English

Every page starts with the header, and the header needs two things from the API: the WhatsApp number and the announcement text. The server will not send **any** of the page until the header is ready. The grey loading skeletons do not help, because they sit below the header.

Normally this costs nothing. Vercel keeps a saved copy of those settings and hands it over at once, even an old one, while it fetches a fresh copy in the background.

The problem needs two things at the same moment:

1. Vercel has **no saved copy at all**, and
2. the API is **asleep**, which it is after about 15 quiet minutes.

Then the shopper looks at a white page with a spinning tab until the API wakes, at worst 60 seconds. That one shopper's request also wakes the API and refills the copy, so it heals itself within about a minute.

**The fix:** let the header appear immediately and fill in just those two small pieces when they arrive. It is a small change, and it needs no change to `lib/`.

## When there would be no saved copy

| Event | Empties the copy? | Source |
| --- | --- | --- |
| Settings older than 60 seconds | **No.** It is marked old, not deleted, and still served | Next.js code |
| A normal deploy or merge to `master` | **No.** The copy survives deploys | Vercel docs |
| First deploy of the project | Yes, but that has already passed | Vercel docs |
| Someone presses purge in Vercel ("Runtime and Data Cache") | Yes | Vercel docs |
| **Setting or changing `STOREFRONT_API_KEY`**, or changing the API address | **Yes in effect.** The header value is part of the copy's name, so the old copy is never found again | Next.js code |
| **Vercel moving your team from Data Cache to Runtime Cache** | Yes, "expect some additional cache misses". New teams moved from 2026-10-30; existing teams get an email first | Vercel docs |
| Moving the project to another team, for example for Vercel Pro (checklist item 8) | Very likely. Storage is kept per owner and project | Vercel docs, my reading |
| Changing the Vercel function region | Yes, each region has its own copy | Vercel docs |
| The cache fills up | Possible. Least recently used entries go first, and on Hobby and Pro the Data Cache is shared across the team. Unlikely for a shop this size | Vercel docs |
| Age limit | I found no published limit for this cache | Not known |

## Which pages, and how likely

**Not quite every page.** Two groups behave differently:

- **Can go blank:** home, `/saree`, `/sale`, product pages, and the order pages (`/track-order/<number>`, `/order-confirmation/<number>`). These are the pages shoppers land on from ads and shared links.
- **Safe:** about, contact, the policy pages, cart, checkout and `/track-order`. These are built ahead of time, and an old copy is served at once.

**Only a full page load is affected:** opening a link, or refreshing. Clicking around inside the site does not redo the header, so it cannot go blank that way.

**How likely (my estimate, not a measurement):** rare, perhaps a few events a year, and each one hits only the first shopper or two during about a minute. Going live makes it more likely at first, because three checklist jobs are on the trigger list: the storefront key (item 5), Vercel Pro (item 8) and possibly the real domain (item 9).

It is still worth fixing because it is cheap, and because a white page for a minute looks like a dead shop to someone who just tapped an ad.

## What is confirmed and what is inferred

**Confirmed**

- The header waits for the settings, with no loading boundary around it (`components/Header.tsx:18`, `app/layout.tsx:59`). The Next.js guide says `loading.tsx` does not cover a layout.
- With no saved copy, the code waits for the API. With an old copy, it serves that copy at once (Next.js `patch-fetch.js`).
- On the live site, `/` and `/saree` are rendered per visit and `/about` and `/contact` are prerendered, shown by their response headers on 2026-11-01. The cart, checkout and `/track-order` result comes from a local build.
- A test build with no saved copy and an API that never answers stalled on the settings call. It failed after 3 attempts of 60 seconds each. See "Also found".

**Inferred, not reproduced**

- **The blank page itself.** Dev servers are yours to run, so I have not seen it in a browser. Test 1 below settles it in five minutes.
- How the live site behaves during a real wake-up. The API was awake when I measured it (0.2 seconds).
- What Render sends while waking. I assume it holds the request. If it answers with an error instead, that page shows the default settings sooner.

## The options

### (a) Header paints at once; the two pieces load inside Suspense. Recommended

The header stops waiting. The chat link and the announcement strip each get a stand-in until the settings arrive.

- A shopper sees the header and the page skeleton straight away, even in the worst case.
- Nothing wrong can get saved, because prerendered pages wait for the real value (see below).
- Costs a little care over layout shift, covered next.

### (b) A much shorter settings timeout, say 3 seconds

One line in `lib/api.ts`, with no layout risk. But:

- The shopper still gets a white page, for 3 seconds instead of 60.
- The API takes up to a minute to wake, so a short timeout **gives up on the real answer** and shows the default settings instead. Today those match your saved ones. Once you save a real WhatsApp number, the default is still the placeholder `8801700000000`, so **shoppers could message a wrong number**. The product and contact pages use the same call.
- **The defaults can get saved into prerendered pages.** A page rebuilt with the defaults counts as a success and replaces the good copy. It lasts at least 60 seconds, and really until the next rebuild that gets a real answer. In a quiet shop that could be until the next visitor the following day: they see the defaults, and their visit triggers the repair.
- This only happens when there is no saved copy, because Next.js ignores the timeout when refreshing an old copy. So it is limited to the same rare events, but those are exactly when it would fire.

### (c) Both

Over (a) alone, it only fills in the strip sooner on a rare load, and it brings back all the downsides of (b).

### Recommendation

**Do (a) alone and leave the 60-second timeout as it is.** Under (a), a slow answer holds up only a strip and a link, so there is nothing left for a shorter timeout to rescue.

Separately, **a free uptime monitor on `/health` every 5 minutes** (checklist item 4) would keep the API awake, which removes the "asleep" half of this problem and the other slow first loads too. It does not replace (a), since the API can still be down or slow.

## Layout shift: does it stay at 0?

On normal visits to the per-visit pages, assume the stand-ins **do** appear briefly. The live HTML of `/` already sends its loading skeleton first, even when the data is ready moments later. So the stand-ins must take the same space as the real thing.

| Case | Shift | Why |
| --- | --- | --- |
| Chat link | 0 | Top bar has a fixed height; the stand-in looks identical |
| Strip on, text fits one line (today) | **0** | Empty navy strip of the same height (about 48 px); text appears inside it |
| Prerendered pages | **0** | The finished strip is already in the page; no stand-in is sent |
| Strip on, text wraps to two lines on a phone | Small, about 0.02 | The admin allows 120 characters; about 45 fit on a phone (my estimate) |
| **Strip turned off in admin** | **About 0.03 to 0.06** when the stand-in was seen | The empty strip closes and the page moves up |

The last two are calculated, not measured. Both stay under Google's "good" limit of 0.1, but they are not 0. The server cannot know the strip is off until the settings arrive, so no stand-in can be right both ways. **With today's settings CLS stays 0.** If the strip is turned off for long, or an announcement runs long, expect a small non-zero score.

I rejected a zero-height stand-in: it would shift the page on every load while the strip is on, which is the normal case.

## How this fits with `docs/PLAN_PAGE_CACHING.md`

That plan is being written separately, so this is based on its stated goal of caching the home and product pages. The two can merge in either order. This work touches only the header, not `lib/`. Do this one first, because it is smaller and protects `/saree`, `/sale` and the order pages either way.

Points for that plan:

1. **Header fix is safe for cached pages.** A cached page waits for the real settings when it is built, so it holds the finished header and no stand-in.
2. **Suspense does not help a page's first-ever build.** In Next.js code, a cached page being built for the first time on a visit waits for everything, with no streaming and no skeleton. Each deploy starts with an empty page cache on Vercel. So a product page not built during the deploy can show the same white page if the API is asleep, whatever the header does. That plan should build all products at deploy time or accept this.
3. **Errors get cached too.** The home page catches a failed product load and shows "Could not load products". If the page is cached, that message gets saved in the same way as (b)'s defaults. Vercel keeps the old good page only when a rebuild actually fails.

## The work

One pull request in `coovi-storefront`, in this order. It needs about an hour plus your test.

1. **Add `components/HeaderSettings.tsx`** with four small components:
   - `ChatLink`: takes the settings promise and renders today's WhatsApp link.
   - `ChatLinkFallback`: looks the same but goes to `/contact`, so nobody is sent to a guessed number. Contact is prerendered and has the saved number.
   - `Announcement`: today's strip; shows nothing when off or empty.
   - `AnnouncementFallback`: an empty strip using the same classes, marked `aria-hidden`.
   - Share the class strings and the "Chat:" label so the pairs cannot drift apart.
2. **Change `components/Header.tsx`:**
   - Remove `async` and `await`. Call `getShopSettings()` once and pass the promise to both pieces. It never rejects, so this is safe.
   - Passing one promise matters: the timeout signal in `lib/api.ts` turns off Next.js's automatic sharing of identical fetches, so two calls would mean two requests.
   - Wrap each piece in `<Suspense fallback={...}>`.
3. **Add `components/Header.test.tsx`** (below).
4. **Change nothing in `lib/` or `app/layout.tsx`.** `lib/` keeps its full coverage with no new tests. Layout stays as it is, per the design rules.

### Tests

In `components/Header.test.tsx` (`// @vitest-environment jsdom`, mocking `@/lib/api` and the client components):

- **The guard:** with `getShopSettings` never finishing, `Header()` returns straight away and not a promise. This fails if anyone adds the `await` back.
- `getShopSettings` is called once per header.
- `Announcement` shows the text and links to `/saree`; shows nothing when off or when the text is empty.
- The stand-in strip has the same sizing classes as the real one and is not empty.
- `ChatLink` uses the saved number; the stand-in goes to `/contact`.

## How to verify

### Checked by Claude

`pnpm lint`, `pnpm typecheck`, `pnpm test`, `pnpm coverage`, `pnpm build`. Then inspect the built HTML of `/about`: it must contain the real strip and number, no pending marker (`<!--$?-->`) and no stand-in. The route list must stay as it is today.

I already tried this design in a throwaway copy, not in your checkout, against a fake API that answers at once. All 172 tests passed, including the 8 new ones; lint and typecheck were clean; the build passed. The route list was unchanged, and `/about`, `/contact` and `/terms` each came out with the real strip and number, no pending marker and no stand-in. That shows it builds correctly. It does not show the browser behaviour, which is what your tests below are for.

After merge, check the live site:

- `/about` still has no pending markers.
- `/saree` may now have a pending marker before `<header`. That is the fix working.
- PageSpeed Insights shows CLS 0.

### Your test 1: see the white page, then see it gone (5 minutes)

Stop your normal storefront dev server first, then use two terminals.

```bash
# Terminal 1: a fake API that accepts requests and never answers
node -e "require('http').createServer(()=>{}).listen(5099)"

# Terminal 2
cd /d/Work/COOVI/coovi-storefront && NEXT_PUBLIC_API_URL=http://localhost:5099/api pnpm dev
```

Open http://localhost:3000/saree in a private window. The first load also compiles the page, so allow a few extra seconds.

| | What you should see |
| --- | --- |
| **Today, on `master`** | White page and a spinning tab for about 60 seconds, then the whole page at once with the page's "could not load" message |
| **After the fix** | Within a few seconds the header, an empty navy strip and the grey skeletons. About 60 seconds later the strip reads "Shop the festive collection" and the error message replaces the skeletons |

Running it on `master` first is worthwhile: it turns "inferred" into "confirmed". Press Ctrl+C in both terminals when finished.

### Your test 2: nothing jumps (after the fix)

Use the same terminal 2 command, with this fake API in terminal 1. It answers after 5 seconds:

```bash
node -e "require('http').createServer((q,r)=>setTimeout(()=>{r.setHeader('content-type','application/json');r.end(JSON.stringify({success:true,data:{announcementText:'Test strip',announcementActive:true}}))},5000)).listen(5099)"
```

Open http://localhost:3000/about, press F12, and paste this into the Console:

```js
let c=0;new PerformanceObserver(l=>{for(const e of l.getEntries())if(!e.hadRecentInput)c+=e.value;console.log('CLS',c)}).observe({type:'layout-shift',buffered:true})
```

Press Ctrl+Shift+R to reload without the saved copy, paste it again, and watch. The strip should sit empty for 5 seconds, then show "Test strip" with **nothing moving**. CLS should stay 0, or print nothing at all.

To see the known small case, change `announcementActive:true` to `false` and restart the fake API. The strip closes and CLS prints a small number.

## Also found

- **A deploy can fail if the API does not answer.** With no saved copy and an API that never answers, the test build failed: the settings timeout (60 seconds) is the same as Next.js's limit for building a page (60 seconds). A failed deploy leaves the old site live, so shoppers are not affected, and a real API that wakes within a minute should pass on a retry. This plan does not change that. Just retry if a deploy ever fails with "took more than 60 seconds".
- **Good habit:** after setting `STOREFRONT_API_KEY` or changing the API address, open `/saree` yourself once, so you are the one who waits and not a shopper.
- **Set `NEXT_PUBLIC_WHATSAPP_NUMBER` in Vercel** when the real number is ready, as well as saving it in the admin. That makes the fallback number real too, so an API failure can never show the placeholder.

## Decisions for you

1. **Approve option (a) alone**, keeping the 60-second timeout? Recommended.
2. **Stand-in chat link goes to the contact page** for those few moments? Recommended, instead of a number that may be wrong.
3. **Accept the small shift when the strip is off or wraps**, about 0.03 to 0.06 and only on some loads? The alternative is to keep announcements short and the strip on.
4. **Add the free uptime monitor** (checklist item 4)? Five minutes of your time, separate from this work, and it removes most of the risk.

## Sources

- Next.js guides in `node_modules/next/dist/docs/`: `loading.js`, fetching data, incremental static regeneration.
- Next.js 16.3.8 code: `server/lib/patch-fetch.js` (stale copies, dropped timeout, only status 200 saved), `server/lib/incremental-cache/index.js` (the copy's name includes headers), `server/lib/dedupe-fetch.js` (signal turns off sharing), `server/app-render/app-render.js` and `build/templates/app-page-runtime.js` (prerendering waits for everything).
- Vercel docs, read 2026-11-01: [Data Cache](https://vercel.com/docs/caching/runtime-cache/data-cache), [Runtime Cache](https://vercel.com/docs/caching/runtime-cache), [ISR](https://vercel.com/docs/incremental-static-regeneration).
