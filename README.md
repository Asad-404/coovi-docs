# 🛍️ COOVI — Saree E-Commerce

COOVI is a learning-first full-stack saree shop for the Bangladesh market, with a catalogue of about 50 products.

## The three codebases

| Project | Stack | Port | Status |
|---|---|---:|---|
| `coovi-api` | Express 5 + TypeScript + Mongoose + MongoDB Atlas | 5000 | Complete, including admin JWT auth |
| `coovi-storefront` | Next.js 16 + React 19 + Tailwind 4 + Zustand | 3000 | Customer flow complete |
| `coovi-admin` | Vite + React 19 + MUI 9 + React Query | 5173 | Auth, product and order UI complete |

## Start here

- **[QUICK_STATUS.md](QUICK_STATUS.md)** — current state, owner actions, browser checks and resume commands.
- **[API_ENDPOINTS.md](API_ENDPOINTS.md)** — API contract shared by all three apps.
- **[docs/FEATURE_GAPS.md](docs/FEATURE_GAPS.md)** — built, partial and missing business features.
- **[docs/GO_LIVE_CHECKLIST.md](docs/GO_LIVE_CHECKLIST.md)** — actions needed before taking real orders.
- **[CLAUDE.md](CLAUDE.md)** — workspace rules.
- **[tools/screenshot.mjs](tools/screenshot.mjs)** — captures any page at phone or desktop width for design comparison.

## Resume

Read `QUICK_STATUS.md`, then start the app you need using its own project instructions.
