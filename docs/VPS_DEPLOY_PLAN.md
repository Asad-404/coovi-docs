# COOVI VPS Deployment Plan

Last updated: 2026-11-14. Status: **infra files built, waiting on VPS provisioning.**

This document covers the full move from Vercel + Render + Atlas to a single Bangladesh VPS.
Two phases:

- **Phase A — Build now (no VPS needed).** Containerise each app, write orchestration, reverse-proxy,
  backup and deploy scripts. ✅ Done in this pass; files listed in the inventory below.
- **Phase B — On the VPS.** Provision, harden, clone, `docker compose up -d`, issue SSL, point DNS.

---

## Target architecture

```
                      Internet (BDIX peers reach this cheaply)
                                    │
                      ┌─────────────┴──────────────┐
                      │  Nginx :80 / :443           │  SSL termination + reverse proxy
                      │  (coovi_nginx container)    │
                      └───┬─────────────┬───────────┬──┘
                          │             │            │
           coovi.com/www  │  admin.     │  api.      │
                          │             │            │
               ┌──────────▼──┐  ┌───────▼────┐  ┌───▼──────────┐
               │ storefront  │  │   admin    │  │   api         │
               │  :3000      │  │  static    │  │   :5000       │
               │  (Next 16)  │  │  (Nginx)   │  │  (Express 5)  │
               └─────────────┘  └────────────┘  └──────┬────────┘
                                                        │
                                               ┌────────▼────────┐
                                               │   MongoDB        │
                                               │   :27017         │
                                               │  (internal only) │
                                               └─────────────────┘
```

- Only Nginx is exposed to the internet (ports 80 / 443).
- MongoDB is on an internal Docker network; it is never published to the host.
- Each service runs in its own container managed by Docker Compose.

---

## Services at a glance

| Service      | Image base     | Port | Public domain         | Build output           |
|--------------|----------------|------|-----------------------|------------------------|
| coovi-api    | node:22-alpine | 5000 | api.coovi.com         | `tsc` → `node dist/`   |
| storefront   | node:22-alpine | 3000 | coovi.com / www       | next standalone server |
| admin        | nginx:alpine   | 80   | admin.coovi.com       | vite → static files    |
| MongoDB      | mongo:7        | 27017| internal only         | official image          |
| Nginx proxy  | nginx:alpine   | 80, 443 | (all domains)      | official image          |

---

## Phase A file inventory (built in this branch)

### Docs-repo root (`coovi-docs`)

| File                                       | Purpose                                      |
|--------------------------------------------|----------------------------------------------|
| `docs/VPS_DEPLOY_PLAN.md`                  | This document                                |
| `docker-compose.yml`                       | All five services, networks, volumes         |
| `nginx/nginx.conf`                         | Main Nginx config                            |
| `nginx/sites/api.conf`                     | api.coovi.com → coovi-api:5000               |
| `nginx/sites/storefront.conf`              | coovi.com / www → coovi-storefront:3000       |
| `nginx/sites/admin.conf`                   | admin.coovi.com → coovi-admin:80             |
| `scripts/backup.sh`                        | Daily mongodump, gzip, retain 14 days        |
| `scripts/deploy.sh`                        | Pull + rebuild + restart one service or all  |
| `scripts/ssl-issue.sh`                     | First-time Let's Encrypt cert issue          |
| `.env.production.example`                  | Root compose vars (Mongo credentials)        |

### Per-app files (each in its own repo branch `feature/vps-deploy`)

| File                                             | Purpose                                        |
|--------------------------------------------------|------------------------------------------------|
| `coovi-api/Dockerfile`                           | Multi-stage: build → slim node image           |
| `coovi-api/.dockerignore`                        | Keeps node_modules, .env, tests out of image   |
| `coovi-api/.env.production.example`              | API production env shape                       |
| `coovi-storefront/Dockerfile`                    | Next standalone build → slim node image        |
| `coovi-storefront/.dockerignore`                 | Same                                           |
| `coovi-storefront/.env.production.example`       | Storefront production env shape                |
| `coovi-storefront/next.config.ts`                | +`output:'standalone'` when DOCKER_BUILD=true  |
| `coovi-admin/Dockerfile`                         | Vite build → nginx static image                |
| `coovi-admin/.dockerignore`                      | Same                                           |
| `coovi-admin/nginx-spa.conf`                     | SPA client-routing fallback to index.html      |
| `coovi-admin/.env.production.example`            | Admin production env shape                     |

---

## Phase B — When the VPS arrives

### 1. VPS provider (Bangladesh, BDIX, Dhaka, KVM)

| Provider      | Notes                                      |
|---------------|--------------------------------------------|
| Novoserv      | KVM, Dhaka DC, BDIX peered                 |
| BDiX Host     | Native BDIX, NVMe available                |
| ServerBD      | KVM, Dhaka                                 |
| Contabo (SG)  | Fallback if BD stock is out; good price    |

**Minimum spec:** 2 vCPU / 4 GB RAM / 50 GB NVMe / Ubuntu 24.04 LTS.
**Recommended:** 8 GB RAM if the budget allows — Mongo + two Node processes + build spikes fit without stress.

### 2. Harden the server (run as root on first login)

```bash
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

### 3. Install Docker

```bash
# Switch to deploy user for all subsequent steps
curl -fsSL https://get.docker.com | sh
sudo usermod -aG docker deploy
newgrp docker
docker --version && docker compose version
```

### 4. Clone repos

```bash
mkdir -p /home/deploy/coovi && cd /home/deploy/coovi

# Docs repo — brings docker-compose.yml, nginx/, scripts/
git clone https://github.com/Asad-404/coovi-docs.git .
git checkout feature/vps-deploy-plan   # or merge to master first

# App repos — each brings its own Dockerfile
git clone https://github.com/<ORG>/coovi-api.git
git clone https://github.com/<ORG>/coovi-storefront.git
git clone https://github.com/<ORG>/coovi-admin.git
```

### 5. Create real env files

```bash
cp .env.production.example .env.production   # root (Mongo creds)
cp coovi-api/.env.production.example      coovi-api/.env.production
cp coovi-storefront/.env.production.example coovi-storefront/.env.production
cp coovi-admin/.env.production.example    coovi-admin/.env.production
# Edit each one — fill in real secrets, never commit them
```

Generate secrets:

```bash
# JWT_SECRET and STOREFRONT_API_KEY (use same command for each)
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

### 6. First boot

```bash
cd /home/deploy/coovi
docker compose build
docker compose up -d
docker ps   # all five containers should be "Up"
docker compose logs -f coovi-api   # watch API connect to Mongo
```

Smoke test before DNS:

```bash
curl http://localhost:5000/api/health   # → {"status":"ok"}
curl http://localhost:3000              # → HTML
```

### 7. Point DNS, then issue SSL

Point these A records to the VPS IP first:

```
coovi.com       → <VPS IP>
www.coovi.com   → <VPS IP>
api.coovi.com   → <VPS IP>
admin.coovi.com → <VPS IP>
```

Then run the issue script (waits for DNS to propagate first if needed):

```bash
bash scripts/ssl-issue.sh you@coovi.com
```

### 8. Backups cron

```bash
chmod +x scripts/backup.sh
( crontab -l 2>/dev/null; echo "0 2 * * * /home/deploy/coovi/scripts/backup.sh >> /home/deploy/coovi/backups/backup.log 2>&1" ) | crontab -
bash scripts/backup.sh   # test it once manually
```

### 9. Day-to-day deploys

```bash
./scripts/deploy.sh api          # rebuild + restart only the API
./scripts/deploy.sh storefront
./scripts/deploy.sh admin
./scripts/deploy.sh all          # rebuild + restart everything
```

---

## Go-live checklist (VPS-specific additions to GO_LIVE_CHECKLIST.md)

- [ ] VPS provisioned: KVM, 2+ vCPU, 4+ GB RAM, NVMe 50+ GB, Ubuntu 24.04, BDIX/Dhaka
- [ ] SSH hardened: root login off, password auth off, ufw active (22/80/443 only)
- [ ] Docker + Compose installed, `deploy` user in docker group
- [ ] All repos cloned to `/home/deploy/coovi` on the `feature/vps-deploy` branches
- [ ] Real `.env.production` files created from examples (not committed)
- [ ] Fresh `JWT_SECRET` generated and saved in a password manager
- [ ] Fresh `STOREFRONT_API_KEY` generated, identical in API and storefront envs
- [ ] Mongo root credentials set, different from any dev value
- [ ] `docker compose up -d` — all five containers healthy (`docker ps`)
- [ ] `curl localhost:5000/api/health` returns 200
- [ ] DNS A records set for all four (sub)domains
- [ ] SSL certs issued, auto-renew cron active
- [ ] `https://coovi.com`, `https://api.coovi.com/health`, `https://admin.coovi.com` all load
- [ ] Backup script run once manually, nightly cron installed
- [ ] All items in `docs/GO_LIVE_CHECKLIST.md` also completed

---

## Notes

### Self-hosted MongoDB vs Atlas

The compose file self-hosts MongoDB by default: BDIX-local latency, full control, local daily backups.
To keep Atlas instead: remove the `mongodb` service and `mongo_data` volume from `docker-compose.yml`,
set `MONGODB_URI` in `coovi-api/.env.production` to the Atlas connection string.

### Rollback

Each service is a container. Roll back a bad API deploy by checking out the last good commit and rebuilding:

```bash
cd coovi-api && git log --oneline -5
git checkout <good-sha>
cd .. && ./scripts/deploy.sh api
```

Mongo data lives on the `mongo_data` named volume. `docker compose down` does not delete it;
only `docker compose down -v` does. Never run `-v` in production unless you mean to wipe the database.

### Memory budget (4 GB VPS, self-hosted Mongo)

| Component                       | Approx RAM |
|---------------------------------|------------|
| OS + Docker daemon              | ~0.6 GB    |
| MongoDB (WiredTiger cache)      | ~1.2 GB    |
| coovi-api                       | ~0.3 GB    |
| coovi-storefront                | ~0.3 GB    |
| Nginx proxy                     | ~0.05 GB   |
| coovi-admin (nginx static)      | ~0.02 GB   |
| **Total**                       | **~2.5 GB**|

~1.5 GB headroom for build spikes and traffic bursts. Comfortable on 4 GB.
