# CLAUDE.md
This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Workspace

COOVI is a workspace containing three independent app repositories, plus a docs repository at the root:

- `coovi-api` — Express 5, TypeScript, Mongoose, MongoDB REST API on port 5000.
- `coovi-storefront` — Next.js 16 customer storefront on port 3000.
- `coovi-admin` — Vite/React admin panel on port 5173.

Run Git commands, commits, and reviews inside the repository they concern. The workspace root is the private `coovi-docs` repository (default branch `master`, renamed from `main` 2026-10-27): it tracks only the root documents, `docs/` and `tools/`, and its `.gitignore` excludes the three app folders. Never add app code to it.

## Operating rules

- Claude may run tests, lint, typecheck and builds to verify a change (allowed by the owner 2026-10-07).
- Do not start dev servers, previews, seed scripts, or deployments unless explicitly requested. The user runs projects manually.
- Claude may push feature branches and open pull requests with `gh` (allowed by the owner 2026-10-07). Never push `master`, never force-push, and never merge a pull request; the owner merges.
- Ask before changing device, hardware, emulator, OS, or other environment-level configuration.
- Keep credentials and real environment values in each app's ignored `.env` files; use `.env.example` for shared configuration shape.
- Prefer the existing project-specific `CLAUDE.md` and generated instruction files over adding duplicate rules.

## Architecture boundaries

- The API is the source of truth for prices, stock, delivery fees, order totals, order status, and authorization.
- The storefront is a public guest-checkout client; it must send product IDs and quantities rather than authoritative prices or totals.
- The admin panel uses JWT Bearer authentication for protected API operations.
- Changes crossing an app boundary must preserve the API contract and response envelope.

## Current documentation

- `QUICK_STATUS.md` — current status, backlog of unbuilt features, placeholders to replace, and manual resume commands; start here.
- `API_ENDPOINTS.md` — canonical contract shared by all three apps.
- `tools/screenshot.mjs` — captures any page at phone or desktop width for design comparison.
- `docs/ADMIN_FEATURE_PLAN.md` — implementation plan for the admin features in the backlog.
- `docs/FEATURE_GAPS.md` — business features a real shop needs, marked have, partial or missing, with priorities.
- `docs/GO_LIVE_CHECKLIST.md` — prioritized "needed before going live" list; add items when you find them.

## Manual resume commands

```bash
cd /d/Work/COOVI/coovi-api && pnpm dev
cd /d/Work/COOVI/coovi-storefront && pnpm dev
cd /d/Work/COOVI/coovi-admin && pnpm dev
curl http://localhost:5000/api/products
```
