# AIDLC setup: your to-do list

Goal: you give one instruction (`/aidlc <what you want>`) and Claude takes it through spec, build, tests, PR, CI, preview, your merge approval, automatic deploy and a smoke test.
Chosen setup: Render (API) + Vercel (storefront, admin), free tier, production only, free subdomains. Claude pushes feature branches and opens PRs; you approve the merge; Claude never pushes `master`.

Do these in order. Never paste passwords, secrets or connection strings into the chat. They go straight into the Render and Vercel dashboards, and Claude will tell you the exact moment.

- [x] **T1. GitHub CLI.** (done 2026-10-05: installed and signed in.) In PowerShell run `winget install GitHub.cli`, reopen the terminal, then `gh auth login` (GitHub.com, HTTPS, log in with the browser, add the `workflow` scope if asked). Check with `gh auth status`.
- [x] **T2.** (Done 2026-10-07: all three exist and `gh` reaches them.) **Confirm the three GitHub repos exist and are yours:** `Asad-404/coovi-api`, `Asad-404/coovi-storefront`, `Asad-404/coovi-admin`. Private is fine; Render and Vercel free tiers work with private repos.
- [x] **T3.** (Done 2026-10-07: API is live at https://coovi-api.onrender.com, free plan, Singapore, health check `/health`. It still points at the **dev** database and `CORS_ORIGINS` holds guessed Vercel addresses; both change at T5 and after T4.) **Render account** at render.com. Sign up with GitHub and allow access to `coovi-api` only.
- [x] **T4.** (Done 2026-10-07: https://coovi-storefront.vercel.app and https://coovi-admin.vercel.app are live.) **Vercel account** at vercel.com. Sign up with GitHub (Hobby plan) and allow access to `coovi-storefront` and `coovi-admin`.
- [ ] **T5. Production database in Atlas.** Create a new DB user (for example `coovi_prod`) with read/write on a new database named `coovi-prod` only, with a strong password. Keep Network Access at `0.0.0.0/0`. Keep the connection string ready (database name `coovi-prod` in the URL). Do not share it.
- [ ] **T6. Production secrets, saved in a password manager.** A new `JWT_SECRET` (run `node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"`), a production admin email, and a strong admin password (not `admin123`).
- [ ] **T7. Business details to tell Claude (not secrets).** The real WhatsApp number (now the placeholder `8801700000000`), the delivery fee in BDT, and the production admin email.
- [x] **T8. Permission rule change.** (Owner said yes to both on 2026-10-07; the CLAUDE.md edits are committed.) Reply "yes" to both: (a) Claude may push feature branches and open PRs with `gh` (never `master`, never force-push); (b) Claude may run tests, lint and builds during an `/aidlc` run. Claude then updates the CLAUDE.md files.
- [ ] **T9. Optional, not blocking.** An SVG or clean PNG of the real logo, and your own saree photos when ready.

**When done, tell Claude:** `todo done`, plus the T7 details. If a step blocks you (for example `winget` is missing), say which step and Claude will give an alternative.

## What Claude does after "todo done" (in order)

A. Update the CLAUDE.md files (push feature branches and PRs allowed, builds/tests allowed inside `/aidlc`), add `.claude/skills/aidlc/SKILL.md`, PR templates and `tools/smoke.mjs`, and rewrite `DEPLOYMENT_PLAN.md` as the runbook.
B. (Done 2026-10-06: everything is merged to `master`.) Land the pending local work: the storefront is on `feat/diponty-inspired-storefront-ui` with no upstream, the API is 1 commit ahead and the admin 2 commits ahead of `origin/master`. One PR per repo, merged after CI is green. The default branch is `master`.
C. Production hardening of the API: `render.yaml`, prod admin seed uses the new credentials, no demo data in prod, fix the duplicate `orderNumber` index warning.
D. CI workflows: the storefront has one; the API and admin ones are in pull request #5 of each repo (opened 2026-10-07, green). Still to do: branch protection on `master`.
E. Deploy wiring: Render service from `render.yaml`, Vercel projects, `coovi-admin/vercel.json` (SPA rewrite), env vars (`NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL`, `VITE_API_URL`, `CORS_ORIGINS`), with you pasting the secrets into the dashboards.
F. Go-live check with `tools/smoke.mjs` and a manual order from browse to admin status change.

After that, every feature is one instruction: `/aidlc <instruction>`. Suggested first features come from the backlog in `QUICK_STATUS.md` (order notifications, delivery fee by area).

Full plan: `C:\Users\ASADUZZAMAN\.claude\plans\stop-all-running-server-staged-dewdrop.md`.
