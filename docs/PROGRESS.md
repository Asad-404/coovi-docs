# 🚀 Coovi E-Commerce - Development Progress

**Task log + learnings** (status/resume info lives in QUICK_STATUS.md; API contract in API_ENDPOINTS.md)

**Git (per user rule — commit after every achievement, separate repo per codebase):**
- `coovi-api` repo: pushed → https://github.com/Asad-404/coovi-api
- `coovi-storefront` repo: 5 achievement commits (6 total incl. scaffold), pushed → https://github.com/Asad-404/coovi-storefront
- Root `D:\Work\COOVI` is NOT a repo (docs live untracked)

---

## ✅ Completed Tasks

### 1. MongoDB Atlas Setup ✅
- Created free M0 cluster: `coovi-cluster`
- Database user created: `coovi_user`
- Network access configured: `0.0.0.0/0` (allow from anywhere)
- Connection string obtained and configured

**Connection String:**
```
mongodb://coovi_user:<PASSWORD>@ac-p1eugs4-shard-00-XX.rzzjqxu.mongodb.net:27017/...
```
> ⚠️ Full connection string with password lives ONLY in `coovi-api/.env` (gitignored). Never commit credentials to git.
**Status:** ✅ Connected and Working

---

### 2. Backend Project Structure ✅
**Location:** `D:\Work\coovi\coovi-api`

**Installed Dependencies:**
- express (5.2.1)
- mongoose (9.10.1)
- cors (2.8.6)
- dotenv (17.4.2)
- typescript (7.0.2)
- ts-node-dev (2.0.0)
- tsx (4.23.13)
- @types/node, @types/express, @types/cors

**Files Created:**
```
coovi-api/
├── .env                      ✅ MongoDB connection configured
├── .gitignore                ✅ Node modules ignored
├── package.json              ✅ Scripts configured
├── tsconfig.json             ✅ TypeScript configured
└── src/
    ├── index.ts              ✅ Express server entry point
    ├── config/
    │   └── database.ts       ✅ MongoDB connection logic
    ├── models/
    │   ├── Product.ts        ✅ Product schema with text search index
    │   └── Order.ts          ✅ Order schema with status tracking
    └── routes/
        ├── products.ts       ✅ CRUD + pagination/search/sort
        └── orders.ts         ✅ Create, list, update status with stock management
```

---

### 3. Database Models ✅

#### Product Model
- slug (unique, required)
- name, nameBn (English/Bengali names)
- description, descriptionBn
- price (BDT, whole numbers)
- images[] (array of URLs)
- size (optional)
- category (default: "Saree")
- stock (number, decreases on order confirmation)
- inStock (boolean)
- Indexes: text search on name, price, category

#### Order Model
- orderNumber (auto-generated: ORD-YYYYMMDD-XXX)
- customerName, phone, address
- items[] (productId, name, price, quantity, image, size)
- subtotal, deliveryFee, total
- status (Pending → Processing → Shipped → Delivered → Cancelled)
- paymentMethod (Cash on Delivery)
- notes (optional)
- Indexes: orderNumber, phone, status, createdAt

---

### 4. API Routes ✅

#### Products API (`/api/products`)
- `GET /` - List all products with pagination, search, sort
  - Query params: page, limit, search, sort (newest|price-asc|price-desc|name-asc|name-desc), category
- `GET /:slug` - Get single product by slug
- `POST /` - Create product (admin)
- `PUT /:id` - Update product (admin)
- `DELETE /:id` - Delete product (admin)

#### Orders API (`/api/orders`)
- `POST /` - Create new order
- `GET /` - List all orders (admin, with pagination & status filter)
- `GET /:orderNumber` - Get order by order number
- `PATCH /:id/status` - Update order status (admin)
  - Stock decreases when: Pending → Processing
  - Stock restored when: Processing → Cancelled

---

### 5. Express Server Configuration ✅
- CORS enabled (allow all origins)
- JSON body parser
- URL-encoded parser
- Route registration
- 404 handler
- Development error messages
- Server startup with MongoDB connection

---

### Task #6: Test Backend Server
**Status:** ✅ COMPLETE  
**Resolution:** MongoDB connection working successfully!

**Testing Results:**
- ✅ Server running on http://localhost:5000
- ✅ GET /api/products - Returns 5 sample products
- ✅ GET /api/orders - Returns empty array (as expected)
- ✅ All routes responding correctly

**Sample Products Loaded:**
1. Red Cotton Saree - ৳1,299
2. Blue Silk Saree - ৳2,499
3. Green Georgette Saree - ৳1,799
4. Maroon Banarasi Saree - ৳3,499
5. Pink Chiffon Saree - ৳1,599

**Backend Process:**
- Running in background (task ID: bl4ctrcs2)
- Command: `cd /d/Work/COOVI/coovi-api && pnpm dev`
- Port: 5000
- Database: Connected to MongoDB Atlas

---

### Task #7: Add Sample Product Data
**Status:** ✅ COMPLETE  
**Method:** Used existing seed.ts script (already run)

**Products in Database:**
All 5 products successfully loaded with:
- English & Bengali names
- Proper pricing in BDT
- Stock management
- Multiple images (using Unsplash placeholders)
- Text search indexing active

---

### Task #8: Initialize Next.js Storefront
**Status:** ✅ COMPLETE  
**Result:** Project scaffolded with `pnpm create next-app@latest` — Next.js 16.3.5, React 19, TypeScript, Tailwind CSS 4 (CSS-first config, no tailwind.config.ts), App Router, **no src/ directory** (files live at root: `app/`, `components/`, `lib/`).

---

### Task #9: Storefront Displays Products ✅
**Status:** ✅ COMPLETE (2026-09-19 evening session)

**What was built:**
- `.env.local` → `NEXT_PUBLIC_API_URL=http://localhost:5000/api`
- `next.config.ts` → `images.remotePatterns` for `images.unsplash.com` (required for next/image with remote URLs)
- `lib/types.ts` → Product interface matching backend model
- `lib/api.ts` → `getProducts()` + `getProductBySlug()` using plain `fetch` (Next.js 16: no axios needed in Server Components)
- `lib/utils.ts` → `formatPrice()` (৳ formatting)
- `components/Header.tsx` → sticky header, COOVI logo, Shop + Cart links (Server Component)
- `components/Footer.tsx` → simple footer
- `components/ProductCard.tsx` → image, name + Bengali name, price, out-of-stock badge, links to `/products/[slug]`
- `app/page.tsx` → async Server Component: fetches products from API, renders hero + responsive grid (1/2/3 cols), friendly error state if backend is down, empty state if no products
- `app/layout.tsx` → Header/Footer wrap all pages, COOVI metadata

**Key Next.js 16 learnings:**
- Pages are async Server Components by default — `await fetch()` directly in the component
- `fetch` is NOT cached by default in Next 16
- `LayoutProps<"/">` is a globally generated type (no import needed, created by next dev/typegen)
- No `'use client'` needed anywhere yet — no interactivity
- Product cards link to `/products/[slug]` which does not exist yet (404 — that's the next task)

**Testing done:**
- ✅ GET / → 200, all 5 product names in server-rendered HTML
- ✅ Prices (৳1,299–৳3,499), Unsplash images, header, footer all present
- ⏳ Visual/responsive check in browser still to do manually

---

### Task #10: Product Detail Page ✅
**Status:** ✅ COMPLETE (2026-09-19 evening session)

**What was built:** `app/products/[slug]/page.tsx`
- Async Server Component with `PageProps<"/products/[slug]">` (global type)
- `const { slug } = await props.params` — dynamic params are Promises in Next 16
- `notFound()` from `next/navigation` when product doesn't exist (returns proper 404)
- `generateMetadata()` — per-product page title + description (SEO)
- Layout: primary image + thumbnail row, category/name/nameBn, price, stock status, EN+BN descriptions, size/category table, Add to Cart button (disabled placeholder until cart exists)

**Tested:**
- ✅ `/products/red-cotton-saree` → 200, product content in HTML
- ✅ `/products/does-not-exist` → 404
- ✅ No compile errors

---

## ⏳ Next Tasks (In Order)

### Task #11: Shopping Cart (Zustand) ✅
**Status:** ✅ COMPLETE (2026-09-19 evening session)

**What was built:**
- `pnpm add zustand` (5.0.15)
- `lib/cartStore.ts` — Zustand store: addItem, removeItem, updateQuantity, clearCart + `persist` middleware (localStorage key: `coovi-cart`) + cartTotal/cartCount helpers
- `lib/types.ts` — added CartItem interface
- `components/AddToCartButton.tsx` — FIRST `'use client'` component. Shows "Added ✓" for 2s after click
- `components/CartBadge.tsx` — client component in header with live cart count. Uses `mounted` guard (useEffect) to avoid hydration mismatch between server HTML and localStorage
- `app/cart/page.tsx` — cart page: items with thumbnails, quantity +/−, remove, clear, subtotal. Checkout button disabled (next task)
- Header + detail page wired up

**Key concepts learned:**
- `'use client'` directive — marks component boundary for browser-side React (state, events, browser APIs)
- Zustand persist middleware — cart survives refresh via localStorage
- Hydration mismatch — server can't read localStorage, so badge renders count only after mount
- Props to Client Components must be serializable (pass a plain object, not the whole Mongoose doc)

**Tested:** detail 200 + cart 200, no compile errors. Interactive behavior (clicks, persistence) needs manual browser test.

---

## ⏳ Next Tasks (In Order)

### Task #12: Checkout → Order Placement ✅
**Status:** ✅ COMPLETE (2026-09-19 evening session)

**What was built:**
- `app/checkout/page.tsx` — guest checkout form (customerName, phone, address as single string, optional notes) with order summary sidebar (subtotal + delivery ৳60 + total). Controlled inputs, submitting state, error display. On success: clearCart() + redirect to confirmation
- `app/order-confirmation/[orderNumber]/page.tsx` — Server Component fetches order by number, shows ✓ banner, order number, items, totals, status, address, COD note. 404 via notFound() for unknown orders
- `lib/api.ts` — added `getOrderByNumber()`
- `lib/types.ts` — added Order + OrderItem interfaces
- `lib/utils.ts` — `DELIVERY_FEE = 60`
- Cart page checkout button enabled

**Important discovery:** Backend expects `address` as a STRING (not an object — SETUP_STOREFRONT.md was wrong). Client sends subtotal/deliveryFee/total (server trusts them — fine for learning; real shops recompute server-side to prevent tampering).

**Tested end-to-end:**
- ✅ POST /api/orders with exact storefront body → order created (ORD-20260919-558)
- ✅ /checkout → 200 (SSR shows empty state; browser hydrates cart → form)
- ✅ /order-confirmation/ORD-20260919-558 → 200 with order data
- ✅ /order-confirmation/ORD-bogus → 404

**THE ENTIRE CUSTOMER FLOW NOW WORKS:** browse → detail → add to cart → checkout → order in MongoDB.

---

## ⏳ Next Tasks (In Order)

### Task #13: Push repos to GitHub ✅ COMPLETE (2026-09-19, done manually by user)
- `coovi-api` → https://github.com/Asad-404/coovi-api (branch: master, in sync)
- `coovi-storefront` → https://github.com/Asad-404/coovi-storefront (branch: master, all 6 commits pushed, clean tree)
- gh CLI turned out not to be needed — repos were created and pushed manually. Go public later only when ready for Vercel.

---

### Task #14: Polish & hardening ✅ (mostly done)
**Done (2026-09-19 evening, commit 19b0bfa):**
- Search box + sort dropdown (newest/price/name) — URL-driven: filters push `?search=`/`?sort=`, server component refetches. Tested: "silk" → 1 result; price-asc → correct order; no-match → friendly message
- Loading skeletons: homepage grid + product detail (animate-pulse, `loading.tsx` conventions)
- Tested no regressions: all routes 200, no dev-log errors

**MobileNav — SKIPPED on purpose:** header has only 2 items (Shop + cart badge) and fits fine at 375px. A hamburger menu would add complexity without value. Revisit if nav grows.

**Not done (future ideas):** pagination/Load More button (API supports ?page=&limit=), category filter UI, product image gallery with thumbnails on detail page

### Task #15: Admin panel — Level 3 ✅ COMPLETE (2026-09-19 → 2026-09-20)

**Step 1 — Backend auth ✅ COMPLETE (2026-09-19, commit c70eefa, pushed by user):**
- `src/models/Admin.ts` — email (unique, lowercase), passwordHash, name, role
- Auto-seed on first server start from ADMIN_EMAIL/ADMIN_PASSWORD in `.env` (bcryptjs hash, cost 10)
- `POST /api/auth/login` → `{ success, data: { token, admin } }` (JWT signed with JWT_SECRET, 1-day expiry)
- `GET /api/auth/me` → current admin (passwordHash excluded)
- `src/middleware/auth.ts` — requireAdmin: verifies `Authorization: Bearer <token>` + role, attaches req.admin
- Protected: product POST/PUT/DELETE, GET /api/orders, PATCH /api/orders/:id/status. Storefront routes stay public.
- `.env` (gitignored): JWT_SECRET (random 64-hex), ADMIN_EMAIL, ADMIN_PASSWORD — dev default admin@coovi.com / admin123 (change it!)
- bcryptjs used (pure JS — no native build issues on Windows); unused native `bcrypt` dep can be uninstalled later

**Key concepts learned (Step 1):**
- **bcrypt hashing** — store passwordHash, never the password; `bcrypt.compare()` on login; same error for wrong email AND wrong password (don't reveal which)
- **JWT** — server signs `{id, email, role}` with JWT_SECRET and verifies the signature on every admin request; stateless (no session storage — logout = client discards the token)
- **Bearer token pattern** — `Authorization: Bearer <token>` header; middleware runs before route handlers, 401/403 on failure
- **TypeScript declaration merging** — `declare global { namespace Express { interface Request { admin?: AdminPayload } } }` teaches TS that req.admin exists
- **dotenv gotcha** — imports evaluate before `dotenv.config()` runs, so `process.env.JWT_SECRET` must be read inside functions, not at module top-level

**Tested (12/12 pass):** login correct/wrong/missing creds; protected routes 401 without token + 200 with token; garbage token 401; /auth/me 200 without passwordHash; public routes unaffected; PATCH no-op status change 200. `tsc --noEmit` clean.

**Step 2 — coovi-admin scaffold ✅ COMPLETE (2026-09-19, commit 5eaa7f7, pushed to github.com/Asad-404/coovi-admin):**
- Scaffolded Vite 8.3 + React 19 + TS 6 (`pnpm create vite coovi-admin --template react-ts`), own git repo initialized
- Installed: MUI 9.4 + icons, React Router 7.18, React Query 5.103, axios, @types/node (dev)
- Deliberately skipped: react-hook-form + x-date-pickers (add when the product form needs them); @types/react-router-dom (deprecated — React Router ships its own types)
- `src/types/index.ts` — CORRECT types matching the real API (address is a string, stock/inStock — NOT the stale SETUP_ADMIN.md versions)
- `src/api/client.ts` — axios instance: Bearer-token request interceptor + auto-logout redirect on expired-token 401
- `src/api/auth.ts` — login/me calls (unwrap `{ success, data }` envelope)
- `src/App.tsx` — routes: /login public; dashboard/products/orders wrapped in ProtectedRoute (localStorage token check — client-side convenience only, real security is the API's requireAdmin)
- `src/components/layout/DashboardLayout.tsx` — AppBar + permanent Drawer (Dashboard/Products/Orders) + Logout button + Outlet
- `src/pages/LoginPage.tsx` — MUI login card, error Alert on 401, stores `admin_token` in localStorage
- `src/pages/DashboardPage.tsx` — FIRST React Query usage: fetches GET /auth/me with the stored token
- Products/Orders placeholder pages; theme (Roboto, borderRadius 8, no uppercase buttons); `@/` alias (TS 6: paths WITHOUT baseUrl — baseUrl is deprecated in TS 6)
- Verified: `tsc -b` clean, `pnpm build` passes, dev server serves on 5173. Browser login flow NOT yet tested (user to verify manually — steps in QUICK_STATUS.md).

**Key concepts learned (Step 2):**
- **SPA vs Next.js** — Vite app is pure client-side: no server components, no SSR; React Router renders pages in the browser
- **Protected routes** — client-side guard checks localStorage, but ANYONE can open devtools — the token check on the API is the real security
- **Axios interceptors** — one place to attach the Bearer token to every request and handle expired-token 401s globally
- **React Query** — `useQuery({ queryKey, queryFn })` handles loading/error states + caching; no manual useEffect/useState fetching
- **TS 6 / Vite 8 changes** — `verbatimModuleSyntax` (type-only imports need `import type`), `paths` without deprecated `baseUrl`, `erasableSyntaxOnly`
- **MUI layout** — AppBar z-index above Drawer, `Toolbar` spacer, `Outlet` renders the active child route

**Step 3 — Admin UI ✅ COMPLETE (2026-09-19, commit a9a46e0, browser-tested + pushed 2026-09-20):**
- `src/api/products.ts` — getAll/getBySlug/create/update/remove; `src/api/orders.ts` — getAll/updateStatus (both unwrap `{ success, data }`)
- `src/utils/format.ts` — formatPrice (৳), formatDate, slugify
- **ProductsPage** — MUI Table: thumbnail+name/nameBn, price, stock chip (red at 0, amber <6), category, Edit/Delete icon actions; "Add Product" button; delete confirmation Dialog
- **ProductFormPage** (at /products/new + /products/:slug/edit) — create/edit in one component (useParams slug decides mode); auto-slug from name until hand-edited (create mode only); EN/BN names + descriptions, price/stock numbers, category/size, in-stock Switch, images as one-URL-per-line textarea; client-side validation before mutation; on success invalidates ['products'] cache and navigates back
- **OrdersPage** — table: order number, date, customer (address in tooltip), item count, total, status Chip (Pending=warning, Processing=info, Shipped=primary, Delivered=success, Cancelled=error) + status Select → PATCH mutation invalidates ['orders']
- Routes wired in App.tsx; edit uses GET /products/:slug (by slug) then PUT /products/:id (by _id) — the API's two different lookups
- Verified: `tsc -b` clean, `pnpm build` passes, dev-server HMR no errors, create-product payload shape confirmed against live API. Browser-tested by user 2026-09-20 — all passed: edit price + save, delete product with confirm dialog, add + delete fake product, order status Pending→Processing with stock drop visible in Products tab, login/logout + wrong-password alert. "Test Saree" deleted during testing.

**Key concepts learned (Step 3):**
- **React Query mutations** — `useMutation({ mutationFn, onSuccess, onError })` + `queryClient.invalidateQueries()` to refetch lists after create/update/delete
- **Cache invalidation** — queries share keys ('products', 'orders', ['product', slug]); invalidating a key re-fetches every active listener
- **MUI Table** — Table/TableHead/Body/Row/Cell + Paper container, hover rows, IconButton actions; confirm-delete via Dialog
- **MUI 9 gotcha** — Stack no longer accepts alignItems/justifyContent as props; put them in `sx={{ alignItems: ... }}`
- **One form, two modes** — `useParams().slug` presence switches create vs edit; `enabled: !!slug` keeps the fetch from firing in create mode; useEffect fills the form when data arrives
- **Derived state** — slug auto-generates from name via slugify() but only until the user edits it (slugEdited flag)

---

### Task #16: Standards review + feature-gap analysis — ✅ COMPLETE (2026-09-20)

**Goal:** Review each codebase one by one (api → storefront → admin) for missing standards, then identify missing standard features vs. a standard small e-commerce app. Deliverable: **CODE_REVIEW.md** at root — every finding gets What → Why → How to fix → Effort (S/M/L). **No fixes in this task** — user picks fixes from the lists as future tasks.

**Context:** Deployment was explored 2026-09-20 (2 agents, all 3 codebases) then DEFERRED — findings preserved in DEPLOYMENT_PLAN.md. SETUP_ADMIN.md archived to docs/archive/ (admin build done; its conventions live in Task #15 above). DIPONTY_ANALYSIS.md kept as feature-reference input for this review; archives after it.

**Method:** 3 parallel review agents (one per codebase) against a standards checklist (validation, error handling, security, typing, duplication, tests; SEO/a11y on frontends); findings compile into CODE_REVIEW.md with a feature-gap section that respects the locked specs (guest checkout, COD only, no accounts, ≤50 products).

**✅ Result:** All 3 codebases fully reviewed (every source file read; findings verified with file:line). **CODE_REVIEW.md** at root — 29 findings (4 cross-codebase + 6 API + 10 storefront + 9 admin), each with What → Why → Fix → Effort (S/M/L), plus 21 missing features (storefront 11, admin 6, API 4) with Must/Should/Could and a suggested fix order. Deployment findings preserved separately in DEPLOYMENT_PLAN.md (deferred). DIPONTY_ANALYSIS.md archived (its feature reference is folded into CODE_REVIEW.md). **No fixes applied — user picks items as future tasks.**

**Key concepts learned (Task #16):**
- **Never trust client-sent prices** — the server must recompute totals from the DB; the browser belongs to the customer
- **Validate at boundaries** — zod schemas on every route's body+query; internal code can trust itself, system edges cannot
- **Mongoose `min` doesn't run on `$inc`/`findByIdAndUpdate`** — schema validation only fires on `save()`, so update-based stock changes can go negative
- **Enumeration as a PII vector** — sequential/guessable order numbers on a public endpoint = harvestable customer data; phone-match is the guest-checkout fix
- **React Query invalidation must cover every affected key** — a status change affects BOTH ['orders'] and ['products']
- **Mass assignment** — passing `req.body` straight into a model lets clients set fields they shouldn't; whitelist inputs

---

### Task #17: Quick-win fixes (review phase 1) + A-1 zod validation — ✅ COMPLETE (2026-09-20)

**Scope:** CODE_REVIEW.md's suggested phase 1 (quick wins) + the A-1 zod validation that a prior session had left uncommitted mid-work. Also: A-6 cleanup + CC-4 test setup + admin quick wins, committed earlier the same day.

**Done this session:**
- **coovi-api (commit d30e997):** A-1 finished — zod schemas on `routes/products.ts`: lenient query validation (bad `page`/`limit`/`sort` fall back to safe defaults, limit clamped 1–50), `escapeRegex()` on search (the `?search=(` → 500 crash), strict body schema (mass assignment like a client-sent `_id` rejected → 400). 9 new tests added (18 total): regex-metachar search, negative page clamp, oversized limit clamp, invalid body → 400, mass-assignment reject, malformed slug reject, valid create → 201, no-token → 401, PUT invalid body → 400.
- **coovi-storefront (commits 384ab98, f15ba72, f5a3897):**
  - **Bonus bug found by `next build`:** `AddToCartButton` passed the raw product (`_id`) where `CartItem` requires `productId` — cart merge/remove and the order payload's `productId` were silently broken at runtime (dev server doesn't type-check). Fixed by mapping `_id` → `productId` in the handler. ⚠️ Old carts in browser localStorage still have the broken shape — clear `coovi-cart` from localStorage if odd behavior.
  - S-4: `postOrder()` added to `lib/api.ts`; checkout uses it, duplicate `API_URL` deleted
  - S-3: homepage "is the backend running?" hint now only renders when `NODE_ENV === "development"`
  - chore: `picsum.photos` allowed in `next.config.ts` remotePatterns
- **Verified earlier same day (prior session, already committed):** admin AD-1/AD-5/AD-8 (7e0b1ca, c822bfd) · API dead deps + `.env.example` + README (68db7ab) · vitest + supertest + mongodb-memory-server setup (a91ffa7)

**Key concepts learned (Task #17):**
- **`next dev` does not type-check** — Turbopack compiles per-request and skips `tsc`; only `next build` runs TypeScript. A type error can run "fine" in dev and still be a real runtime bug (the `_id`/`productId` one was exactly that)
- **Lenient vs strict validation** — public GET query params should fall back to defaults (old links/search engines must never hard-fail); POST/PUT bodies should reject anything unexpected (strictObject stops mass assignment)
- **zod `.catch()` vs `.optional()`** — `.catch(default)` silently repairs bad input (right for public queries); strict schemas reject (right for write bodies)
- **Tests prove the fix** — each A-1 failure mode from the review (regex crash, negative page, oversized limit) now has a red→green test documenting it
- **PUT now requires the full product object** — zod rejects partial update bodies; fine because the admin form always sends every field

**Remaining from CODE_REVIEW.md phases:** phase 2 (API security: CC-1 server-computed totals, A-2 error handler, A-3 stock integrity, A-4/A-5 rate-limit/helmet, CC-2) · phase 3 (robustness) · phase 4 (features)

---

### Task #18: Review phase 2 — API security & correctness — ✅ COMPLETE (2026-09-20)

**Scope:** All six CODE_REVIEW.md phase-2 items, each with proving tests and its own commit.

**coovi-api commits (test suite now 43 tests / 6 files, `tsc --noEmit` clean):**
- **A-2 (f007478):** global 4-arg error handler in `app.ts` — Express 5 auto-forwards rejected async handler promises, so routes need no try/catch; every error returns the `{success, message}` JSON shape (no more HTML error pages)
- **CC-1 + CC-3 (b67c62c):** `POST /api/orders` loads products from the DB and recomputes subtotal/deliveryFee/total itself; the zod body schema accepts ONLY `{customerName, phone, address, notes?, items:[{productId, quantity}]}` — spoofed client prices/totals are silently dropped (non-strict `z.object` on purpose). `DELIVERY_FEE` read from env at call time (default 60)
- **A-3 (9ca6406):** stock taken on Pending→Processing via ONE atomic conditional update `Product.updateOne({_id, stock:{$gte:qty}}, {$inc:{stock:-qty}})` — check-and-write in a single DB operation, so two admins confirming overlapping orders can never drive stock negative; `matchedCount===0` → rollback loop restores earlier decrements, 409 Conflict, order stays Pending. Processing→Cancelled restores stock
- **A-4 + A-5 (c20c75a):** express-rate-limit per-IP windows (login 5/15min, orders 20/h, reads 100/min, lookups 20/min; all `skip` in test env; JSON 429 handler) + helmet headers + CORS locked to `CORS_ORIGINS` env list. Login limiter proven by a test that flips NODE_ENV to production in try/finally
- **CC-2 (fa6d022):** `GET /api/orders/:orderNumber` requires `?phone=`; single query `findOne({orderNumber, phone})` makes wrong-phone and nonexistent-order byte-identical 404s (anti-enumeration)
- **(a5d54e4):** `GET /api/orders/delivery-fee` for checkout display — registered BEFORE `/:orderNumber` or "delivery-fee" would be captured as an orderNumber param

**coovi-storefront (e088b42):**
- `lib/api.ts`: `OrderInput` now sends only `{productId, quantity}` items — no prices/totals; `getOrderByNumber(orderNumber, phone)` passes `?phone=`; new `getDeliveryFee()`
- Checkout: fetches the real fee from the API (hardcoded `DELIVERY_FEE` deleted from `lib/utils.ts`), pre-checks cart quantities against live stock (warning + submit disabled until fixed), redirects to confirmation with `?phone=`
- Confirmation page: requires the phone (order number + phone = guest credentials); no-phone visits get a plain-GET phone-entry form; wrong phone → not-found UI; `robots: {index: false}` in metadata
- End-to-end verified against live servers: fee endpoint 60, order placed sending only productId/quantity, no-phone → form, wrong phone → not-found, right phone → order shown, noindex meta present

**Key concepts learned (Task #18):**
- **Never trust the browser (CC-1)** — client-sent prices are at best stale, at worst malicious; server recomputes from its own DB
- **Atomic check-and-write (A-3)** — `updateOne` with a `$gte` filter in the QUERY makes look-then-write one operation; no race window. `matchedCount===0` is the "not enough stock" signal
- **Rate limiting is per-IP sliding windows (A-4)** — brute-force protection on login, abuse limits elsewhere; JSON 429 not plain text; skip in tests via NODE_ENV
- **CORS is browser-enforced (A-5)** — the server only decides whether to say "this origin may read my response"; helmet adds nosniff/frame/CSP headers cheaply
- **Anti-enumeration (CC-2)** — order number + phone together are guest credentials; identical 404s for wrong-phone vs nonexistent-order leak nothing
- **Express 5 error flow** — rejected promises from async handlers go straight to the 4-arg global handler; per-route try/catch is noise
- **Next.js 16 soft 404s** — once a dynamic page starts streaming its shell, `notFound()` can't change the status code (stays 200 + not-found UI); the bundled docs' answer is `robots: noindex` (added), a real 404 would need a proxy-level check — affects the product detail page too, pre-existing
- **Route order matters** — a literal `/delivery-fee` route must be registered before `/:orderNumber` or it's swallowed by the param

**Remaining from CODE_REVIEW.md:** phase 3 (robustness) · phase 4 (features — Load More is spec'd)

---

## 🔧 Technical Specifications

### Environment
- Node.js: v24.13.0 ✅
- pnpm: 10.28.2 ✅
- TypeScript: 7.0.2 ✅
- MongoDB: Atlas Free Tier (M0) ✅

### Scripts in coovi-api package.json
```json
{
  "dev": "tsx watch src/index.ts",
  "seed": "tsx src/seed.ts",
  "build": "tsc",
  "start": "node dist/index.js"
}
```

### Environment Variables (.env)
```
MONGODB_URI=mongodb+srv://coovi_user:<PASSWORD>@coovi-cluster.rzzjqxu.mongodb.net/coovi?retryWrites=true&w=majority&appName=coovi-cluster
PORT=5000
NODE_ENV=development
JWT_SECRET=<random 64-hex>
ADMIN_EMAIL=<dev default admin@coovi.com — change for prod>
ADMIN_PASSWORD=<dev default — change for prod>
```
> ⚠️ Real values live ONLY in `coovi-api/.env` (gitignored) — never write actual secrets into docs. (Password redacted from this doc 2026-09-20.)

---

## 📝 Notes

- All TypeScript files use strict mode
- Error messages show full details in development mode
- Production mode will hide error details
- Admin auth added 2026-09-19 (JWT): admin routes protected; storefront routes open by design
- Image upload to Cloudinary will be added later
- Currently using placeholder image URLs

---

**2026-09-19 doc cleanup:** 12 stale/overlapping docs moved to docs/archive/ (CURRENT_STATUS, CHECKLIST, START_HERE, planning docs, SETUP_BACKEND/SETUP_STOREFRONT, DATABASE_MODELS). Root now: QUICK_STATUS (status), PROGRESS (this log), API_ENDPOINTS (contract), SETUP_ADMIN (active task ref), DIPONTY_ANALYSIS (reference), README (overview).
