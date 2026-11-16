# COOVI VPS Deployment Plan

Last updated: 2026-11-15. Status: **infra files built, waiting on Lightsail provisioning.**

This document covers the full move from Vercel + Render + Atlas to a single AWS Lightsail
Virtual Server, fronted by Cloudflare, with images built by GitHub Actions and pushed to GHCR.

Two phases:

- **Phase A — Build now (no VPS needed).** Containerise each app, write orchestration, reverse-proxy,
  backup, deploy scripts, and CI/CD workflows. ✅ Done in this pass.
- **Phase B — On the Lightsail VPS.** Provision, harden, clone, pull images, issue SSL, point DNS.

---

## Architecture

```
                 Shoppers (Bangladesh & Global)
                               │
                 ┌─────────────▼──────────────┐
                 │  Cloudflare (Free Plan)    │  DNS, DDoS/Bot Shield, Dhaka BDIX Edge Cache
                 └─────────────┬──────────────┘
                               │ (HTTPS / Full Strict)
                 ┌─────────────▼──────────────┐
                 │ AWS Lightsail ($12/mo)     │  2 vCPU, 2 GB RAM, 60 GB SSD + 4 GB Swap
                 │ Nginx :80 / :443           │  Dual-Stack (Public IPv4 + IPv6)
                 └───┬─────────┬──────────┬───┘
                     │         │          │
       ┌─────────────▼─┐  ┌────▼────┐  ┌──▼────────────┐
       │ storefront    │  │  admin  │  │  api          │
       │ :3000 (Next)  │  │ (Nginx) │  │  :5000 (Expr)│
       └──────┬────────┘  └─────────┘  └──────┬───────┘
              │ (Images)                      │
       ┌──────▼────────┐               ┌──────▼────────┐
       │  Cloudinary   │               │   MongoDB 7   │
       │  (Free CDN)   │               │  (Internal)   │
       └───────────────┘               └───────────────┘
```

### Why this setup

| Decision | Reasoning |
|----------|-----------|
| **Lightsail $12/mo Virtual Server** (not Container Service) | Container Services are stateless — incompatible with self-hosted MongoDB — and cost $40/mo for 2 GB RAM. The Virtual Server gives persistent SSD, full root, and 3 TB transfer for $12. |
| **Dual-Stack ($12) over IPv6-only ($10)** | A dedicated public IPv4 ensures GitHub Actions SSH, `ghcr.io` pulls, Let's Encrypt, and payment/SMS APIs work without NAT64 workarounds. |
| **Singapore (`ap-southeast-1`)** | Full 3 TB transfer allowance. Mumbai halves it to 1.5 TB. |
| **Cloudflare in front** | Free DDoS/bot shield, Dhaka BDIX edge cache for static assets, and hides the origin IP. |
| **GitHub Actions + GHCR** | Builds happen on GitHub's runners (free), not the 2 GB VPS. Next.js 16 builds can spike past 2 GB and would OOM-kill (`Exit Code 137`) on the server. Pre-built images mean the VPS only ever does `docker compose pull`. |
| **Cloudinary** | Product images stored and served from Cloudinary's CDN. The Lightsail container never resizes images — `images.unoptimized: true` in `next.config.ts` offloads all image processing. |

### Monthly cost

| Component | Cost |
|-----------|------|
| AWS Lightsail 2 GB Dual-Stack | $12.00 |
| Cloudflare Free | $0 |
| Cloudinary Free | $0 |
| GitHub Actions (free tier) | $0 |
| GHCR (free for public images) | $0 |
| **Monitoring & Error Tracking** | |
| Sentry (Developer plan) | $0 (free 5K errors/mo) |
| Uptime monitoring (UptimeRobot/BetterUptime) | $0 (free tier) |
| **Total** | **$12.00/mo** |

---

## Services at a glance

| Service      | Image                                  | Port | mem_limit | Public domain         |
|--------------|----------------------------------------|------|-----------|-----------------------|
| coovi-api    | `ghcr.io/asad-404/coovi-api:latest`    | 5000 | 300m      | api.coovi.com         |
| storefront   | `ghcr.io/asad-404/coovi-storefront:latest` | 3000 | 500m | coovi.com / www       |
| admin        | `ghcr.io/asad-404/coovi-admin:latest`   | 80   | 48m       | admin.coovi.com       |
| MongoDB      | `mongo:7`                               | 27017| 400m      | internal only         |
| Nginx proxy  | `nginx:alpine`                          | 80, 443 | 48m   | (all domains)         |

**Total peak runtime cap: ~1.30 GB**, leaving ~250-350 MB headroom for the OS (Ubuntu 24.04 ~200-250MB + Docker daemon ~100-150MB) on the 2 GB instance (plus 4 GB swap as a safety buffer).

---

## CI/CD flow

```
  Push to master (coovi-api repo)
       │
       ▼
  GitHub Actions (ubuntu runner)
   ├── checkout code
   ├── docker build (with build-args for NEXT_PUBLIC_* / VITE_*)
   ├── docker push → ghcr.io/asad-404/coovi-api:latest
   └── SSH into Lightsail → ./scripts/deploy.sh api
                              ├── docker compose pull coovi-api
                              ├── docker compose up -d --no-deps coovi-api
                              └── docker image prune -f
```

Each app repo (coovi-api, coovi-storefront, coovi-admin) has its own `.github/workflows/deploy.yml`
that triggers on push to `master`. The workflow builds the image, pushes it to GHCR, then SSHes
into the Lightsail server and runs the deploy script for that one service.

**Why no on-server builds:** Next.js 16's build process can spike past 2 GB RAM and would be
OOM-killed (`Exit Code 137`) on the 2 GB Lightsail instance. Building on GitHub Actions avoids
this entirely — the server only pulls pre-built images.

---

## Phase A file inventory (built in this branch)

### Docs-repo root (`coovi-docs`)

| File                                       | Purpose                                      |
|--------------------------------------------|----------------------------------------------|
| `docs/VPS_DEPLOY_PLAN.md`                  | This document                                |
| `docs/DEPLOYMENT_EXPLAINED.md`             | Line-by-line explanation of every infra file |
| `docker-compose.yml`                       | All five services, mem_limits, GHCR images  |
| `nginx/nginx.conf`                         | Global Nginx config + Cloudflare real-IP     |
| `nginx/sites/api.conf`                     | api.coovi.com → coovi-api:5000               |
| `nginx/sites/storefront.conf`              | coovi.com / www → coovi-storefront:3000      |
| `nginx/sites/admin.conf`                   | admin.coovi.com → coovi-admin:80             |
| `scripts/backup.sh`                        | Daily mongodump, gzip, retain 14 days        |
| `scripts/deploy.sh`                        | Pull from GHCR + restart one service or all  |
| `scripts/ssl-issue.sh`                     | First-time Let's Encrypt cert issue          |
| `.env.production.example`                  | Root compose vars (Mongo credentials)        |

### Per-app files (each in its own repo, branch `feature/vps-deploy`)

| File                                             | Purpose                                        |
|--------------------------------------------------|------------------------------------------------|
| `coovi-api/Dockerfile`                            | Multi-stage build → slim node image           |
| `coovi-api/.dockerignore`                         | Keeps secrets and junk out of image           |
| `coovi-api/.env.production.example`              | API production env shape                      |
| `coovi-api/.github/workflows/deploy.yml`          | Build → GHCR → SSH deploy                     |
| `coovi-storefront/Dockerfile`                    | Next standalone build → slim node image        |
| `coovi-storefront/.dockerignore`                 | Same                                          |
| `coovi-storefront/.env.production.example`        | Storefront production env shape               |
| `coovi-storefront/.github/workflows/deploy.yml`   | Build with NEXT_PUBLIC_* args → GHCR → SSH    |
| `coovi-storefront/next.config.ts`                 | `output:'standalone'` + `images.unoptimized`  |
| `coovi-admin/Dockerfile`                          | Vite build → nginx static image                |
| `coovi-admin/.dockerignore`                      | Same                                          |
| `coovi-admin/nginx-spa.conf`                     | SPA client-routing fallback                    |
| `coovi-admin/.env.production.example`            | Admin production env shape                     |
| `coovi-admin/.github/workflows/deploy.yml`       | Build with VITE_* args → GHCR → SSH deploy    |

---

## Phase B — When the Lightsail VPS is provisioned

### 1. Provision the instance

- **Service:** AWS Lightsail → Virtual Server (not Container Service)
- **Plan:** $12/month — 2 vCPU, 2 GB RAM, 60 GB SSD, 3 TB transfer
- **Platform:** Ubuntu 24.04 LTS
- **Region:** Singapore (`ap-southeast-1`) for the full 3 TB transfer allowance
- **Networking:** Dual-Stack (IPv4 + IPv6) — confirm the instance has a public IPv4

### 2. Lightsail Networking firewall

In the **Lightsail Console → Networking → IPv4 Firewall**, open:

| Port | Protocol | Source | Purpose |
|------|----------|--------|---------|
| 22   | TCP      | (restricted — see below) | SSH for GitHub Actions deploys |
| 80   | TCP      | Any (or Cloudflare IPs) | HTTP |
| 443  | TCP      | Any (or Cloudflare IPs) | HTTPS |

For SSH, restrict port 22 to GitHub Actions runner IP ranges if possible, or to your own IP for manual access. GitHub Actions runner IPs are published in the `actions` meta API.

> **Note:** The Lightsail firewall is separate from `ufw` inside Ubuntu. Both must allow the ports. Cloudflare's proxy means the origin only ever receives traffic from Cloudflare's IP ranges — you can optionally restrict 80/443 to those ranges for extra security.

### 3. Harden the server

```bash
# As root, first login
apt update && apt upgrade -y

# Create a non-root deploy user
adduser deploy
usermod -aG sudo deploy
rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy/

# Harden SSH
sed -i 's/#PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sed -i 's/#PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
systemctl restart sshd

# Firewall — only 22, 80, 443
ufw default deny incoming
ufw default allow outgoing
ufw allow ssh && ufw allow 80/tcp && ufw allow 443/tcp
ufw enable

# Fail2ban
apt install -y fail2ban && systemctl enable --now fail2ban
```

### 4. Create a 4 GB swap file

The 2 GB RAM instance needs swap as a safety buffer for MongoDB and Node memory spikes.

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make it permanent across reboots
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Lower swappiness so swap is only used under pressure
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
free -h   # should show 2 GB RAM + 4 GB swap
```

### 5. Install Docker

```bash
# As deploy user
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker deploy
newgrp docker
docker --version && docker compose version
```

### 6. Clone the docs repo

```bash
mkdir -p /home/deploy/coovi && cd /home/deploy/coovi

# Docs repo — brings docker-compose.yml, nginx/, scripts/
git clone https://github.com/Asad-404/coovi-docs.git .
git checkout master   # or the deploy-plan branch if not yet merged
```

The app repos are **not** cloned to the server. Images come from GHCR — the server only needs
the `docker-compose.yml`, `nginx/` configs, `scripts/`, and `.env.production` files.

### 7. Log in to GHCR on the server

```bash
# Create a GitHub Personal Access Token (classic) with read:packages scope
echo "YOUR_GHCR_TOKEN" | docker login ghcr.io -u Asad-404 --password-stdin
```

### 8. Create real env files

```bash
cp .env.production.example .env.production   # root (Mongo creds)
cp coovi-api/.env.production.example      coovi-api/.env.production
cp coovi-storefront/.env.production.example coovi-storefront/.env.production
cp coovi-admin/.env.production.example    coovi-admin/.env.production
# Edit each one — fill in real secrets, never commit them
```

Generate secrets:

```bash
# JWT_SECRET and STOREFRONT_API_KEY
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

> **Note:** `NEXT_PUBLIC_*` and `VITE_*` variables are NOT in these files. They are baked
> into the images at build time by GitHub Actions from repository Secrets. Set them in
> GitHub → Settings → Secrets and variables → Actions:
> - `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL`, `NEXT_PUBLIC_WHATSAPP_NUMBER` (storefront)
> - `VITE_API_URL` (admin)
> - `VPS_HOST`, `VPS_SSH_KEY` (all three repos, for the SSH deploy step)

### 9. First boot

```bash
cd /home/deploy/coovi
docker compose pull   # pulls all images from GHCR
docker compose up -d
docker ps   # all five containers should be "Up"
docker compose logs -f coovi-api   # watch API connect to Mongo
```

Smoke test before DNS:

```bash
curl http://localhost:5000/api/health   # → {"status":"ok"}
curl http://localhost:3000              # → HTML
```

### 10. Cloudflare DNS

In the Cloudflare dashboard, add A records (Proxied / Orange Cloud enabled):

| Name | Type | Content | Proxy |
|------|------|---------|-------|
| coovi.com | A | Lightsail IPv4 | Proxied |
| www.coovi.com | A (or CNAME) | Lightsail IPv4 | Proxied |
| api.coovi.com | A | Lightsail IPv4 | Proxied |
| admin.coovi.com | A | Lightsail IPv4 | Proxied |

Set **SSL/TLS mode** to **Full (Strict)**. This means Cloudflare connects to your origin over
HTTPS and verifies the Let's Encrypt cert.

### 11. Issue SSL certificates

Cloudflare's Full (Strict) mode requires a valid cert on the origin. Two options:

**Option A — Let's Encrypt (recommended, free):**

```bash
bash scripts/ssl-issue.sh you@coovi.com
```

> Cloudflare must be in "DNS only" (grey cloud) mode temporarily for the HTTP-01 challenge to
> reach the origin directly, OR use Cloudflare's API to do a DNS-01 challenge. Simplest: temporarily
> switch the four records to DNS-only, run the script, then switch back to Proxied.

**Option B — Cloudflare Origin CA cert:**

Create an Origin Certificate in Cloudflare → SSL/TLS → Origin Server. Copy the cert and key
to the server and update the Nginx `ssl_certificate` paths. This cert is only trusted by
Cloudflare, not by browsers — but since Cloudflare is in front, browsers see Cloudflare's own
edge cert (which is trusted).

### 12. Backups cron

```bash
chmod +x scripts/backup.sh
( crontab -l 2>/dev/null; echo "0 2 * * * /home/deploy/coovi/scripts/backup.sh >> /home/deploy/coovi/backups/backup.log 2>&1" ) | crontab -
bash scripts/backup.sh   # test it once manually
```

### 13. Day-to-day deploys

Deploys happen automatically via GitHub Actions on push to `master`. For manual deploys:

```bash
./scripts/deploy.sh api          # pull + restart only the API
./scripts/deploy.sh storefront
./scripts/deploy.sh admin
./scripts/deploy.sh all          # pull + restart everything
```

---

## GitHub Secrets required

Set these in **each** app repo under Settings → Secrets and variables → Actions:

### All three repos

| Secret | Example | Purpose |
|--------|---------|---------|
| `VPS_HOST` | `43.218.x.x` | Lightsail public IPv4 for SSH deploy |
| `VPS_SSH_KEY` | `-----BEGIN OPENSSH...` | Private key for the `deploy` user |

### coovi-storefront only

| Secret | Example | Purpose |
|--------|---------|---------|
| `NEXT_PUBLIC_API_URL` | `https://api.coovi.com/api` | Baked into JS bundle at build time |
| `NEXT_PUBLIC_SITE_URL` | `https://coovi.com` | Baked into JS bundle at build time |
| `NEXT_PUBLIC_WHATSAPP_NUMBER` | `8801712345678` | Baked into JS bundle at build time |

### coovi-admin only

| Secret | Example | Purpose |
|--------|---------|---------|
| `VITE_API_URL` | `https://api.coovi.com/api` | Baked into JS bundle at build time |

> `GITHUB_TOKEN` is provided automatically by GitHub Actions — no need to create it manually.
> It has permission to push to `ghcr.io` because the workflow sets `packages: write`.

---

## Go-live checklist

- [ ] Lightsail instance provisioned: 2 vCPU, 2 GB RAM, 60 GB SSD, Ubuntu 24.04, Singapore
- [ ] Dual-Stack confirmed (public IPv4 + IPv6)
- [ ] Lightsail firewall open: 22 (restricted), 80, 443
- [ ] SSH hardened: root login off, password auth off, ufw active
- [ ] 4 GB swap file created and persistent across reboots
- [ ] Docker + Compose installed, `deploy` user in docker group
- [ ] Server logged in to GHCR (`docker login ghcr.io`)
- [ ] Docs repo cloned to `/home/deploy/coovi`
- [ ] Real `.env.production` files created (Mongo creds, JWT_SECRET, STOREFRONT_API_KEY, etc.)
- [ ] Fresh `JWT_SECRET` and `STOREFRONT_API_KEY` generated and saved in a password manager
- [ ] GitHub Secrets set: `VPS_HOST`, `VPS_SSH_KEY` in all three repos
- [ ] GitHub Secrets set: `NEXT_PUBLIC_*` in storefront, `VITE_API_URL` in admin
- [ ] `docker compose pull && docker compose up -d` — all five containers healthy
- [ ] `curl localhost:5000/api/health` returns 200
- [ ] Cloudflare DNS A records set (Proxied) for all four domains
- [ ] Cloudflare SSL/TLS set to Full (Strict)
- [ ] SSL certs issued (Let's Encrypt or Cloudflare Origin CA)
- [ ] `https://coovi.com`, `https://api.coovi.com/health`, `https://admin.coovi.com` all load
- [ ] Nginx real-IP working: check access log shows visitor IPs, not Cloudflare edge IPs
- [ ] Backup script run once manually, nightly cron installed
- [ ] All items in `docs/GO_LIVE_CHECKLIST.md` also completed

---

## Notes

### Memory budget (2 GB Lightsail + 4 GB swap)

| Component                        | Approx RAM | mem_limit |
|----------------------------------|------------|-----------|
| Ubuntu 24.04 base                | ~0.20-0.25 GB | —      |
| Docker daemon                    | ~0.10-0.15 GB | —      |
| MongoDB (WiredTiger cache 0.25 GB)| ~0.40 GB   | 400m      |
| coovi-api                        | ~0.30 GB   | 300m      |
| coovi-storefront                 | ~0.50 GB   | 500m      |
| Nginx proxy                      | ~0.04 GB   | 48m       |
| coovi-admin (nginx static)       | ~0.04 GB   | 48m       |
| **Total OS + containers**        | **~1.58-1.68 GB** | **1.30 GB** |

Leaves ~250-350 MB free RAM with 4 GB swap as overflow. Comfortable headroom for traffic spikes. The mem_limits prevent any single container from OOM-killing the others. If you upgrade to a 4 GB instance later, remove the mem_limits and the `--wiredTigerCacheSizeGB` cap for better performance.

### Cloudflare real IP

Cloudflare proxies every request, so without the `set_real_ip_from` directives in `nginx.conf`,
Nginx sees all traffic coming from Cloudflare's edge IPs. Rate limiting in the API would then
treat all visitors as one. The `real_ip_header CF-Connecting-IP` directive restores the real
visitor IP. Update the IP ranges from https://www.cloudflare.com/ips/ periodically.

### Performance Reality & Migration Path

**Current plan:** Self-hosted MongoDB on the 2 GB Lightsail instance with tight memory limits.

**Reality check:** The allocated memory is **minimum viable**. Under low-to-moderate traffic (20-50 daily users), the setup will work fine. However, as traffic grows, you may experience:

- MongoDB cache pressure → slower queries (disk reads instead of RAM cache hits)
- Memory spikes during peak hours → swap usage → 5-10x slower response times
- Occasional OOM risk during traffic surges (e.g., Friday evening with 30-50 concurrent users)

**Monitoring indicators that you need more resources:**

```bash
# Check memory usage
docker stats --no-stream

# Check swap usage (if consistently >500MB, you need more RAM)
free -h

# Watch for OOM kills in logs
docker compose logs | grep -i "killed"
```

**When any of these happen consistently:**
- Swap usage stays above 500 MB during normal traffic
- API response times exceed 1 second
- MongoDB queries take >500ms (check with MongoDB slow query log)
- Containers getting OOM-killed

**Migration options (in order of cost):**

#### Option A: Move MongoDB to Atlas Free Tier (Recommended first step)
**Cost:** $0 additional (still $12/mo total)

Frees up 400 MB on the VPS, giving breathing room to the API and Storefront.

**Steps:**
1. Create MongoDB Atlas account, provision free M0 cluster (512 MB shared, 5 GB storage)
2. Backup current data: `bash scripts/backup.sh`
3. Restore to Atlas: `mongorestore --uri="mongodb+srv://..." --archive=mongo_backup.gz --gzip`
4. Update `docker-compose.yml`:
   - Remove `mongodb` service
   - Remove `mongo_data` volume
   - Remove `internal` network (or keep it, doesn't hurt)
5. Update `coovi-api/.env.production`:
   - Set `MONGODB_URI=mongodb+srv://<user>:<pass>@cluster.xxxxx.mongodb.net/coovi?retryWrites=true&w=majority`
6. Redeploy: `docker compose up -d`
7. Increase container limits:
   - API: 300m → 500m (heap: 220m → 380m)
   - Storefront: 500m → 800m (heap: 380m → 620m)
   - Total: 1.40 GB (600 MB free for OS + spikes)

#### Option B: Upgrade to 4 GB Lightsail
**Cost:** $24/mo (+$12)

Remove all `mem_limit` constraints, let containers use what they need. Better performance, no worries.

**Steps:**
1. Snapshot the 2 GB instance in Lightsail console
2. Create new 4 GB instance from snapshot
3. Update DNS to new IP (or use static IP attached to the instance)
4. Remove all `mem_limit` and `NODE_OPTIONS` from `docker-compose.yml`
5. Update MongoDB: `command: []` (remove WiredTiger cache limit)

#### Option C: Hybrid (Atlas + 4GB VPS)
**Cost:** $24-34/mo

Atlas free tier + 4 GB Lightsail. Overkill for current scale but sets you up for serious growth.

---

**Recommendation:** Start with the current self-hosted setup. Monitor closely for 2-4 weeks. If you hit performance issues, go with **Option A** (Atlas free tier) first — it costs nothing and solves most problems. Only upgrade to 4 GB if Atlas free tier limits become a bottleneck (100 connections, 5 GB storage).

---

## Monitoring & Observability

Running a production VPS without monitoring is flying blind. You need to know about errors before your users complain.

### Error Tracking — Sentry (Recommended)

**Why Sentry:**
- Catches unhandled exceptions in Node.js (API, Storefront)
- Source maps for React/Next.js errors
- Performance monitoring (slow API endpoints, slow page loads)
- Release tracking (know which deploy caused an issue)
- Free tier: 5,000 errors/month (plenty for early stage)

**Setup:**

1. **Create Sentry account** at https://sentry.io
2. **Create three projects:**
   - `coovi-api` (Node.js / Express)
   - `coovi-storefront` (Next.js)
   - `coovi-admin` (React)

3. **Install SDK in each app:**

**API (`coovi-api`):**
```bash
pnpm add @sentry/node @sentry/profiling-node
```

Add to `src/index.ts` (before any imports):
```typescript
import * as Sentry from "@sentry/node";
import { nodeProfilingIntegration } from "@sentry/profiling-node";

Sentry.init({
  dsn: process.env.SENTRY_DSN,
  environment: process.env.NODE_ENV,
  tracesSampleRate: 0.1, // 10% of requests for performance monitoring
  profilesSampleRate: 0.1,
});
```

**Storefront (`coovi-storefront`):**
```bash
pnpm add @sentry/nextjs
```

Run setup wizard:
```bash
npx @sentry/wizard@latest -i nextjs
```

**Admin (`coovi-admin`):**
```bash
pnpm add @sentry/react
```

Add to `src/main.tsx`:
```typescript
import * as Sentry from "@sentry/react";

Sentry.init({
  dsn: import.meta.env.VITE_SENTRY_DSN,
  environment: import.meta.env.MODE,
  integrations: [
    Sentry.browserTracingIntegration(),
    Sentry.replayIntegration(),
  ],
  tracesSampleRate: 0.1,
  replaysSessionSampleRate: 0.1,
  replaysOnErrorSampleRate: 1.0,
});
```

4. **Add env vars:**

GitHub Secrets (for build-time injection):
- Storefront: `NEXT_PUBLIC_SENTRY_DSN`
- Admin: `VITE_SENTRY_DSN`

Server env (`.env.production`):
- API: `SENTRY_DSN=https://...@o...ingest.sentry.io/...`

5. **Upload source maps (for readable stack traces):**

Add to each `.github/workflows/deploy.yml` after build:
```yaml
- name: Upload source maps to Sentry
  env:
    SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
    SENTRY_ORG: your-org-name
    SENTRY_PROJECT: coovi-api  # or coovi-storefront, coovi-admin
  run: |
    npx @sentry/cli releases new ${{ github.sha }}
    npx @sentry/cli releases files ${{ github.sha }} upload-sourcemaps ./dist --url-prefix ~/
    npx @sentry/cli releases finalize ${{ github.sha }}
```

---

### Uptime Monitoring

**Option 1: UptimeRobot (Easiest)**
- Free tier: 50 monitors, 5-minute checks
- Setup: https://uptimerobot.com
- Add monitors for:
  - `https://coovi.com` (GET, expect 200)
  - `https://api.coovi.com/api/health` (GET, expect 200)
  - `https://admin.coovi.com` (GET, expect 200)
- Alert via email/SMS when down

**Option 2: BetterUptime (Better free tier)**
- Free tier: unlimited monitors, 3-minute checks, 1 phone call/month
- Setup: https://betteruptime.com
- Same monitors as above
- Optional: Create a `/api/health` endpoint that checks MongoDB connection:
  ```typescript
  app.get('/api/health', async (req, res) => {
    try {
      await mongoose.connection.db.admin().ping();
      res.json({ status: 'ok', db: 'connected' });
    } catch (err) {
      res.status(503).json({ status: 'error', db: 'disconnected' });
    }
  });
  ```

---

### Server Monitoring

**Option 1: Docker Stats Dashboard (Free, self-hosted)**

Create a simple monitoring script on the server:

`/home/deploy/coovi/scripts/monitor.sh`:
```bash
#!/bin/bash

echo "=== Memory Usage ==="
free -h

echo ""
echo "=== Swap Usage ==="
swapon --show

echo ""
echo "=== Disk Usage ==="
df -h | grep -E "Filesystem|/dev/root"

echo ""
echo "=== Container Stats ==="
docker stats --no-stream --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.MemPerc}}"

echo ""
echo "=== Docker Disk Usage ==="
docker system df
```

Make it executable and run daily via cron:
```bash
chmod +x /home/deploy/coovi/scripts/monitor.sh
crontab -e
# Add:
0 9 * * * /home/deploy/coovi/scripts/monitor.sh | mail -s "COOVI Daily Health" you@email.com
```

**Option 2: Netdata (Free, web dashboard)**

Install on the VPS:
```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

Access at `http://YOUR_VPS_IP:19999`. Real-time charts for CPU, RAM, disk, network, and per-container metrics.

**Option 3: Prometheus + Grafana (Advanced, overkill for 2GB)**

Skip this unless you upgrade to 4GB+. Too resource-heavy for the current setup.

---

### Log Management

**Current approach (acceptable for small scale):**
```bash
# View logs
docker compose logs -f coovi-api
docker compose logs --tail=100 coovi-storefront

# Search logs for errors
docker compose logs coovi-api | grep -i error

# Export logs for analysis
docker compose logs --since 24h coovi-api > api-errors.log
```

**Upgrade path (when needed):**
- **Papertrail** (free 50MB/month) — aggregates logs from all containers, searchable web UI
- **Loki + Grafana** (self-hosted, but needs more RAM)

For now, Sentry captures errors automatically, so log aggregation is optional.

---

### Monitoring Checklist

- [ ] Sentry installed in API, Storefront, Admin
- [ ] Sentry DSNs added to GitHub Secrets and server env files
- [ ] Source maps uploaded in GitHub Actions workflows
- [ ] Uptime monitoring configured (UptimeRobot or BetterUptime)
- [ ] Health check endpoint created (`/api/health`)
- [ ] Server monitoring script created and scheduled (daily email)
- [ ] Or Netdata installed for real-time dashboard
- [ ] Test: Trigger an error in each app, verify it appears in Sentry
- [ ] Test: Stop a container, verify uptime monitor alerts you

---

### Monitoring costs summary

| Service | Tier | Cost | Limits |
|---------|------|------|--------|
| Sentry | Developer (free) | $0 | 5K errors/mo, 1 user |
| UptimeRobot | Free | $0 | 50 monitors, 5-min checks |
| Netdata | Free (self-hosted) | $0 | Uses ~50-80MB RAM |
| **Total** | | **$0** | |

**When to upgrade:**
- Sentry: when you exceed 5K errors/month or need more users → Team plan $26/mo
- UptimeRobot: when you need <5min checks or more monitors → $7/mo

### Rollback

Each service is a container tagged `:latest` on GHCR. To roll back, you need the previous image
digest or a versioned tag. Consider tagging images with the commit SHA in addition to `:latest`
for easy rollbacks:

```bash
# On the server, pull a specific older image
docker pull ghcr.io/asad-404/coovi-api@sha256:<previous-digest>
docker compose up -d --no-deps coovi-api
```

Mongo data lives on the `mongo_data` named volume. `docker compose down` does not delete it;
only `docker compose down -v` does. Never run `-v` in production unless you mean to wipe the database.

### Cloudflare cache and Next.js ISR

Cloudflare's edge cache will serve cached HTML. Next.js ISR revalidation still works because
Cloudflare forwards the request to the origin on a cache miss, and the origin (Next.js) serves
the revalidated page. If you need to bust Cloudflare's cache for a specific page, use the
Cloudflare dashboard → Caching → Purge → Custom Purge by URL.
