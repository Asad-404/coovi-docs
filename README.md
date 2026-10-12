# 🛍️ COOVI — Saree E-Commerce

Learning-first full-stack project: a real store for a saree business (Bangladesh market). Max ~50 products, brand "Coovi".

## The three codebases (each with its own git repo)

This root folder is the private `coovi-docs` repo. It holds only these documents and `tools/`; the three app folders are ignored here.

| Project | Stack | Port | Status |
|---|---|---|---|
| `coovi-api` | Express 5 + TypeScript + Mongoose + MongoDB Atlas | 5000 | ✅ Complete, including admin JWT auth — [github.com/Asad-404/coovi-api](https://github.com/Asad-404/coovi-api) |
| `coovi-storefront` | Next.js 16 + React 19 + Tailwind 4 + Zustand | 3000 | ✅ Customer flow complete — [github.com/Asad-404/coovi-storefront](https://github.com/Asad-404/coovi-storefront) |
| `coovi-admin` | Vite 8 + React 19 + MUI 9 + React Query | 5173 | ✅ Auth, product, and order UI complete |

## Documentation

- **QUICK_STATUS.md** — where the project is right now + how to resume. **Start here.**
- **API_ENDPOINTS.md** — the API contract between all three codebases (updated 2026-10-04)
- **tools/screenshot.mjs** — captures any page at phone or desktop width for design comparison
- **`docs/ADMIN_FEATURE_PLAN.md`** — implementation plan for the admin features in the backlog
- **`CLAUDE.md`** — workspace-wide rules; each app has its own project-specific `CLAUDE.md`
## Resume in one line

Read `QUICK_STATUS.md` — it has the current task, the state of each server, and resume commands.
