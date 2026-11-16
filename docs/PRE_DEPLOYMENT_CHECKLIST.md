# COOVI Pre-Deployment Checklist

**Purpose:** Complete these tasks before deploying to AWS Lightsail production environment.

**Status:** 🟡 In Progress

**Last updated:** 2026-11-15

---

## Phase A: Infrastructure & Config Files ✅

All infrastructure files are ready in the `coovi-docs` repo:

- [x] `docker-compose.yml` with corrected memory limits
- [x] `nginx/nginx.conf` with Cloudflare real-IP configuration
- [x] `nginx/sites/api.conf`
- [x] `nginx/sites/storefront.conf`
- [x] `nginx/sites/admin.conf`
- [x] `scripts/deploy.sh`
- [x] `scripts/backup.sh`
- [x] `scripts/ssl-issue.sh`
- [x] `.env.production.example` files
- [x] Documentation: `VPS_DEPLOY_PLAN.md`, `DEPLOYMENT_EXPLAINED.md`

---

## Phase B: Application Code Updates

### B1: API (`coovi-api` repo) 🔴 TODO

**Branch:** `feature/vps-deploy` (already exists)

#### Dockerfile & Docker Configuration
- [ ] Verify `Dockerfile` exists with multi-stage build
- [ ] Verify `.dockerignore` exists
- [ ] Test local Docker build: `docker build -t coovi-api-test .`
- [ ] Test run locally: `docker run -p 5000:5000 --env-file .env coovi-api-test`

#### Environment Variables
- [ ] Create `.env.production.example` with all required variables:
  - `NODE_ENV=production`
  - `PORT=5000`
  - `MONGODB_URI=mongodb://coovi_user:CHANGE_ME@coovi_mongo:27017/coovi?authSource=admin`
  - `JWT_SECRET=CHANGE_ME`
  - `STOREFRONT_API_KEY=CHANGE_ME`
  - `TRUST_PROXY=1`
  - `SENTRY_DSN=https://...` (placeholder)
  - `SENTRY_ENVIRONMENT=production`

#### Health Check Endpoint
- [ ] Create `/api/health` endpoint in `src/index.ts`:
  ```typescript
  app.get('/api/health', async (req, res) => {
    try {
      await mongoose.connection.db.admin().ping();
      res.json({ 
        status: 'ok', 
        db: 'connected',
        uptime: process.uptime(),
        timestamp: new Date().toISOString()
      });
    } catch (err) {
      res.status(503).json({ 
        status: 'error', 
        db: 'disconnected',
        error: err.message 
      });
    }
  });
  ```
- [ ] Test health endpoint locally

#### Sentry Integration
- [ ] Install Sentry: `pnpm add @sentry/node @sentry/profiling-node`
- [ ] Add Sentry initialization in `src/index.ts` (before other imports):
  ```typescript
  import * as Sentry from "@sentry/node";
  import { nodeProfilingIntegration } from "@sentry/profiling-node";

  if (process.env.NODE_ENV === 'production' && process.env.SENTRY_DSN) {
    Sentry.init({
      dsn: process.env.SENTRY_DSN,
      environment: process.env.SENTRY_ENVIRONMENT || 'production',
      tracesSampleRate: 0.1,
      profilesSampleRate: 0.1,
    });
  }
  ```
- [ ] Add Sentry error handler middleware (after all routes, before other error handlers):
  ```typescript
  app.use(Sentry.Handlers.errorHandler());
  ```
- [ ] Test Sentry by triggering a test error

#### GitHub Actions CI/CD
- [ ] Verify `.github/workflows/deploy.yml` exists
- [ ] Update workflow with Sentry source maps upload:
  ```yaml
  - name: Upload source maps to Sentry
    if: success()
    env:
      SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
      SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
      SENTRY_PROJECT: coovi-api
    run: |
      npm install -g @sentry/cli
      sentry-cli releases new ${{ github.sha }}
      sentry-cli releases files ${{ github.sha }} upload-sourcemaps ./dist --url-prefix ~/
      sentry-cli releases finalize ${{ github.sha }}
  ```

#### Testing
- [ ] Run tests: `pnpm test`
- [ ] Build: `pnpm build`
- [ ] Verify `dist/` output

---

### B2: Storefront (`coovi-storefront` repo) 🔴 TODO

**Branch:** `feature/vps-deploy` (already exists)

#### Dockerfile & Docker Configuration
- [ ] Verify `Dockerfile` exists with multi-stage build
- [ ] Verify build args: `DOCKER_BUILD`, `NEXT_PUBLIC_API_URL`, `NEXT_PUBLIC_SITE_URL`, `NEXT_PUBLIC_WHATSAPP_NUMBER`
- [ ] Verify `.dockerignore` exists
- [ ] Test local Docker build with args:
  ```bash
  docker build \
    --build-arg DOCKER_BUILD=true \
    --build-arg NEXT_PUBLIC_API_URL=http://localhost:5000/api \
    --build-arg NEXT_PUBLIC_SITE_URL=http://localhost:3000 \
    --build-arg NEXT_PUBLIC_WHATSAPP_NUMBER=8801712345678 \
    -t coovi-storefront-test .
  ```
- [ ] Test run locally: `docker run -p 3000:3000 coovi-storefront-test`

#### Next.js Configuration
- [ ] Verify `next.config.ts` has:
  ```typescript
  const isDockerBuild = process.env.DOCKER_BUILD === "true";
  
  const nextConfig: NextConfig = {
    ...(isDockerBuild && { output: "standalone" }),
    images: {
      unoptimized: true, // Cloudinary handles optimization
    },
  };
  ```
- [ ] Test build locally: `DOCKER_BUILD=true pnpm build`
- [ ] Verify `.next/standalone/` folder is created

#### Environment Variables
- [ ] Create `.env.production.example`:
  - `NODE_ENV=production`
  - `STOREFRONT_API_KEY=CHANGE_ME` (server-side secret)
  - `NEXT_PUBLIC_API_URL` (note: in GitHub Secrets, not this file)
  - `NEXT_PUBLIC_SITE_URL` (note: in GitHub Secrets, not this file)
  - `NEXT_PUBLIC_WHATSAPP_NUMBER` (note: in GitHub Secrets, not this file)
  - `NEXT_PUBLIC_SENTRY_DSN` (note: in GitHub Secrets, not this file)

#### Sentry Integration
- [ ] Install Sentry: `pnpm add @sentry/nextjs`
- [ ] Run Sentry setup wizard: `npx @sentry/wizard@latest -i nextjs`
- [ ] Verify `sentry.client.config.ts` created
- [ ] Verify `sentry.server.config.ts` created
- [ ] Verify `sentry.edge.config.ts` created
- [ ] Update configs to use env vars:
  ```typescript
  Sentry.init({
    dsn: process.env.NEXT_PUBLIC_SENTRY_DSN,
    environment: process.env.NODE_ENV,
    tracesSampleRate: 0.1,
  });
  ```

#### GitHub Actions CI/CD
- [ ] Verify `.github/workflows/deploy.yml` exists
- [ ] Verify build args include all `NEXT_PUBLIC_*` variables from GitHub Secrets
- [ ] Add Sentry source maps upload step (Sentry wizard should add this automatically)

#### Testing
- [ ] Run tests: `pnpm test`
- [ ] Build: `pnpm build`
- [ ] Verify standalone output

---

### B3: Admin (`coovi-admin` repo) 🔴 TODO

**Branch:** `feature/vps-deploy` (already exists)

#### Dockerfile & Docker Configuration
- [ ] Verify `Dockerfile` exists with multi-stage build (build + nginx)
- [ ] Verify build arg: `VITE_API_URL`, `VITE_SENTRY_DSN`
- [ ] Verify `.dockerignore` exists
- [ ] Verify `nginx-spa.conf` exists with SPA fallback
- [ ] Test local Docker build:
  ```bash
  docker build \
    --build-arg VITE_API_URL=http://localhost:5000/api \
    --build-arg VITE_SENTRY_DSN=https://... \
    -t coovi-admin-test .
  ```
- [ ] Test run locally: `docker run -p 8080:80 coovi-admin-test`

#### Environment Variables
- [ ] Create `.env.production.example`:
  - `VITE_API_URL` (note: in GitHub Secrets, not this file)
  - `VITE_SENTRY_DSN` (note: in GitHub Secrets, not this file)

#### Sentry Integration
- [ ] Install Sentry: `pnpm add @sentry/react`
- [ ] Add Sentry to `src/main.tsx`:
  ```typescript
  import * as Sentry from "@sentry/react";

  if (import.meta.env.PROD && import.meta.env.VITE_SENTRY_DSN) {
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
  }
  ```
- [ ] Test Sentry by triggering a test error

#### Vite Configuration
- [ ] Verify `vite.config.ts` has source maps enabled for production:
  ```typescript
  export default defineConfig({
    build: {
      sourcemap: true, // For Sentry
    },
  });
  ```

#### GitHub Actions CI/CD
- [ ] Verify `.github/workflows/deploy.yml` exists
- [ ] Verify build args include `VITE_API_URL` and `VITE_SENTRY_DSN` from GitHub Secrets
- [ ] Add Sentry source maps upload:
  ```yaml
  - name: Upload source maps to Sentry
    if: success()
    env:
      SENTRY_AUTH_TOKEN: ${{ secrets.SENTRY_AUTH_TOKEN }}
      SENTRY_ORG: ${{ secrets.SENTRY_ORG }}
      SENTRY_PROJECT: coovi-admin
    run: |
      npm install -g @sentry/cli
      sentry-cli releases new ${{ github.sha }}
      sentry-cli releases files ${{ github.sha }} upload-sourcemaps ./dist/assets --url-prefix ~/assets
      sentry-cli releases finalize ${{ github.sha }}
  ```

#### Testing
- [ ] Run tests: `pnpm test`
- [ ] Build: `pnpm build`
- [ ] Verify `dist/` output

---

## Phase C: External Services Setup

### C1: Sentry (Error Tracking) 🔴 TODO

- [ ] Create Sentry account at https://sentry.io
- [ ] Create organization (e.g., "coovi")
- [ ] Create three projects:
  - [ ] `coovi-api` (Node.js / Express)
  - [ ] `coovi-storefront` (Next.js)
  - [ ] `coovi-admin` (React)
- [ ] Copy DSN for each project
- [ ] Create Sentry Auth Token (Settings → Auth Tokens → Create New Token)
  - Scopes: `project:releases`, `project:write`
- [ ] Save for GitHub Secrets setup

### C2: Uptime Monitoring 🔴 TODO

**Choose one:**

**Option A: UptimeRobot**
- [ ] Create account at https://uptimerobot.com
- [ ] Add monitor: `https://coovi.com` (HTTP, 5-min interval)
- [ ] Add monitor: `https://api.coovi.com/api/health` (HTTP, 5-min interval)
- [ ] Add monitor: `https://admin.coovi.com` (HTTP, 5-min interval)
- [ ] Configure alert contacts (email, SMS)

**Option B: BetterUptime**
- [ ] Create account at https://betteruptime.com
- [ ] Add monitor: `https://coovi.com` (HTTP, 3-min interval)
- [ ] Add monitor: `https://api.coovi.com/api/health` (HTTP, 3-min interval)
- [ ] Add monitor: `https://admin.coovi.com` (HTTP, 3-min interval)
- [ ] Configure alert contacts (email, phone call)

---

## Phase D: GitHub Configuration

### D1: GitHub Packages (GHCR) 🔴 TODO

- [ ] Verify GitHub account has Packages enabled
- [ ] Verify repos are public (or set up private package access)
- [ ] Test GHCR push permissions in GitHub Actions (already configured in workflows)

### D2: GitHub Secrets 🔴 TODO

**Set these in EACH app repo (Settings → Secrets and variables → Actions):**

#### All three repos (`coovi-api`, `coovi-storefront`, `coovi-admin`):
- [ ] `VPS_HOST` = Lightsail public IPv4 (e.g., `43.218.x.x`)
- [ ] `VPS_SSH_KEY` = Private SSH key for `deploy` user (entire key including `-----BEGIN OPENSSH PRIVATE KEY-----`)
- [ ] `SENTRY_AUTH_TOKEN` = Token from Sentry
- [ ] `SENTRY_ORG` = Your Sentry organization slug (e.g., `coovi`)

#### `coovi-api` only:
- [ ] `SENTRY_PROJECT` = `coovi-api`

#### `coovi-storefront` only:
- [ ] `NEXT_PUBLIC_API_URL` = `https://api.coovi.com/api`
- [ ] `NEXT_PUBLIC_SITE_URL` = `https://coovi.com`
- [ ] `NEXT_PUBLIC_WHATSAPP_NUMBER` = `8801712345678` (replace with real)
- [ ] `NEXT_PUBLIC_SENTRY_DSN` = DSN from Sentry storefront project
- [ ] `SENTRY_PROJECT` = `coovi-storefront`

#### `coovi-admin` only:
- [ ] `VITE_API_URL` = `https://api.coovi.com/api`
- [ ] `VITE_SENTRY_DSN` = DSN from Sentry admin project
- [ ] `SENTRY_PROJECT` = `coovi-admin`

---

## Phase E: AWS Lightsail Provisioning

### E1: Create Instance 🔴 TODO

- [ ] Log in to AWS Lightsail console
- [ ] Click "Create instance"
- [ ] Select region: **Singapore (ap-southeast-1)**
- [ ] Select platform: **Linux/Unix**
- [ ] Select blueprint: **OS Only → Ubuntu 24.04 LTS**
- [ ] Select instance plan: **$12/month** (2 vCPU, 2 GB RAM, 60 GB SSD)
- [ ] Verify: **Dual-Stack** enabled (IPv4 + IPv6)
- [ ] Name instance: `coovi-production`
- [ ] Click "Create instance"
- [ ] Wait for instance to be "Running"
- [ ] Note down public IPv4 address

### E2: Networking & Firewall 🔴 TODO

- [ ] In Lightsail console, go to instance → Networking tab
- [ ] IPv4 Firewall rules:
  - [ ] SSH (22) - **Custom** - Your IP or GitHub Actions IP ranges
  - [ ] HTTP (80) - **Any** (or Cloudflare IP ranges)
  - [ ] HTTPS (443) - **Any** (or Cloudflare IP ranges)
- [ ] Optional: Create and attach a **Static IP** (free in Lightsail)
  - Prevents IP change if you restart the instance
  - Update `VPS_HOST` GitHub Secret if you attach static IP

### E3: SSH Access 🔴 TODO

- [ ] Download default SSH key from Lightsail console
- [ ] SSH into instance: `ssh -i LightsailDefaultKey.pem ubuntu@<VPS_IP>`
- [ ] Verify connection

---

## Phase F: Server Setup

### F1: System Hardening 🔴 TODO

Connect via SSH as `ubuntu` user:

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Create deploy user
sudo adduser deploy
# Set a strong password (store in password manager)

# Add deploy to sudo group
sudo usermod -aG sudo deploy

# Copy SSH keys to deploy user
sudo rsync --archive --chown=deploy:deploy ~/.ssh /home/deploy/
```

Reconnect as `deploy` user:

```bash
ssh -i LightsailDefaultKey.pem deploy@<VPS_IP>
```

Continue hardening:

```bash
# Disable root login and password auth
sudo sed -i 's/^#*PermitRootLogin .*/PermitRootLogin no/' /etc/ssh/sshd_config
sudo sed -i 's/^#*PasswordAuthentication .*/PasswordAuthentication no/' /etc/ssh/sshd_config
sudo systemctl restart sshd

# Configure firewall
sudo ufw default deny incoming
sudo ufw default allow outgoing
sudo ufw allow ssh
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw --force enable
sudo ufw status

# Install fail2ban
sudo apt install -y fail2ban
sudo systemctl enable fail2ban
sudo systemctl start fail2ban
```

- [ ] System updated
- [ ] `deploy` user created
- [ ] SSH keys copied
- [ ] Root login disabled
- [ ] Password auth disabled
- [ ] UFW firewall enabled
- [ ] Fail2ban installed

### F2: Create Swap File 🔴 TODO

```bash
# Create 4GB swap file
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile

# Make permanent
echo '/swapfile none swap sw 0 0' | sudo tee -a /etc/fstab

# Lower swappiness
echo 'vm.swappiness=10' | sudo tee -a /etc/sysctl.conf
sudo sysctl -p

# Verify
free -h
```

- [ ] Swap file created
- [ ] Swap enabled
- [ ] Swap persistent across reboots
- [ ] Swappiness set to 10
- [ ] Verified with `free -h`

### F3: Install Docker & Docker Compose 🔴 TODO

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh

# Add deploy user to docker group
sudo usermod -aG docker deploy

# Apply group change (or logout/login)
newgrp docker

# Verify
docker --version
docker compose version
```

- [ ] Docker installed
- [ ] Docker Compose installed
- [ ] `deploy` user in docker group
- [ ] Verified versions

### F4: Clone Docs Repo 🔴 TODO

```bash
# Create project directory
mkdir -p /home/deploy/coovi
cd /home/deploy/coovi

# Clone docs repo (contains docker-compose.yml, nginx/, scripts/)
git clone https://github.com/Asad-404/coovi-docs.git .

# Switch to main branch (or feature branch if not merged yet)
git checkout main
```

- [ ] Directory created
- [ ] Docs repo cloned
- [ ] On correct branch

### F5: GitHub Container Registry Login 🔴 TODO

```bash
# Create GitHub Personal Access Token (classic)
# Go to: https://github.com/settings/tokens
# Scopes: read:packages
# Copy token

# Login to GHCR
echo "YOUR_GITHUB_TOKEN" | docker login ghcr.io -u Asad-404 --password-stdin
```

- [ ] GitHub PAT created with `read:packages` scope
- [ ] Logged in to GHCR
- [ ] Verified: `docker pull ghcr.io/asad-404/coovi-api:latest` works (after first deploy)

### F6: Create Environment Files 🔴 TODO

```bash
cd /home/deploy/coovi

# Root .env.production (for docker-compose.yml)
cp .env.production.example .env.production
nano .env.production
```

Edit `.env.production`:
```bash
MONGO_USER=coovi_admin
MONGO_PASS=<generate-strong-password>
```

Generate secrets:
```bash
# Generate MongoDB password
openssl rand -base64 32

# Generate JWT_SECRET
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"

# Generate STOREFRONT_API_KEY
node -e "console.log(require('crypto').randomBytes(32).toString('hex'))"
```

Create API env file:
```bash
# Note: These will be created AFTER first image is pulled, or create manually
mkdir -p /home/deploy/coovi/coovi-api
nano /home/deploy/coovi/coovi-api/.env.production
```

Add to `coovi-api/.env.production`:
```bash
NODE_ENV=production
PORT=5000
MONGODB_URI=mongodb://coovi_admin:<MONGO_PASS>@coovi_mongo:27017/coovi?authSource=admin
JWT_SECRET=<generated-jwt-secret>
STOREFRONT_API_KEY=<generated-storefront-api-key>
TRUST_PROXY=1
SENTRY_DSN=<from-sentry-dashboard>
SENTRY_ENVIRONMENT=production
```

Create Storefront env file:
```bash
mkdir -p /home/deploy/coovi/coovi-storefront
nano /home/deploy/coovi/coovi-storefront/.env.production
```

Add to `coovi-storefront/.env.production`:
```bash
NODE_ENV=production
STOREFRONT_API_KEY=<same-as-api-storefront-api-key>
```

**Note:** `NEXT_PUBLIC_*` and `VITE_*` vars are NOT in these files — they're baked into images at build time via GitHub Secrets.

- [ ] Root `.env.production` created with MongoDB credentials
- [ ] MongoDB password generated and saved in password manager
- [ ] JWT_SECRET generated and saved
- [ ] STOREFRONT_API_KEY generated and saved
- [ ] API `.env.production` created
- [ ] Storefront `.env.production` created
- [ ] All secrets stored securely in password manager

### F7: Monitoring Script 🔴 TODO

```bash
cd /home/deploy/coovi/scripts
nano monitor.sh
```

Add content:
```bash
#!/bin/bash

echo "=== COOVI Health Report $(date) ==="
echo ""

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
echo ""

echo "=== Recent Errors (last hour) ==="
docker compose -f /home/deploy/coovi/docker-compose.yml logs --since 1h 2>&1 | grep -i error | tail -20
```

Make executable:
```bash
chmod +x /home/deploy/coovi/scripts/monitor.sh

# Test it
./monitor.sh
```

Optional: Setup daily email report (requires mail server configuration):
```bash
# Install mailutils
sudo apt install -y mailutils

# Add to crontab
crontab -e
# Add line:
# 0 9 * * * /home/deploy/coovi/scripts/monitor.sh 2>&1 | mail -s "COOVI Daily Health" you@email.com
```

- [ ] `monitor.sh` created
- [ ] Script made executable
- [ ] Tested manually
- [ ] Optional: Daily cron job configured

### F8: Optional - Install Netdata 🔴 TODO

For real-time monitoring dashboard:

```bash
bash <(curl -Ss https://my-netdata.io/kickstart.sh)
```

Access at `http://<VPS_IP>:19999`

**Security note:** Netdata is exposed on port 19999. Either:
- Only access via SSH tunnel: `ssh -L 19999:localhost:19999 deploy@<VPS_IP>`
- Or restrict in UFW: `sudo ufw allow from YOUR_IP to any port 19999`

- [ ] Netdata installed (optional)
- [ ] Accessed dashboard
- [ ] Secured port 19999

---

## Phase G: Cloudflare Setup

### G1: Domain DNS Configuration 🔴 TODO

Log in to Cloudflare dashboard:

- [ ] Add domain `coovi.com` to Cloudflare (if not already)
- [ ] Create A records (all with Proxy enabled - orange cloud):
  - [ ] `coovi.com` → Lightsail IPv4
  - [ ] `www.coovi.com` → Lightsail IPv4 (or CNAME to `coovi.com`)
  - [ ] `api.coovi.com` → Lightsail IPv4
  - [ ] `admin.coovi.com` → Lightsail IPv4
- [ ] Wait for DNS propagation (5-10 minutes)
- [ ] Test: `dig coovi.com` should show Cloudflare IPs (not your VPS IP directly)

### G2: SSL/TLS Configuration 🔴 TODO

- [ ] In Cloudflare: SSL/TLS → Overview → Set mode to **Full (Strict)**
- [ ] In Cloudflare: SSL/TLS → Edge Certificates → Enable:
  - [ ] Always Use HTTPS: ON
  - [ ] Minimum TLS Version: 1.2
  - [ ] Automatic HTTPS Rewrites: ON

---

## Phase H: First Deployment

### H1: Initial Deploy 🔴 TODO

On the VPS:

```bash
cd /home/deploy/coovi

# Pull all images from GHCR
# (This will fail if images haven't been built yet - that's OK, build them first via GitHub Actions)
docker compose pull

# Start all services
docker compose up -d

# Check status
docker ps

# Should see 5 containers:
# - coovi_mongo
# - coovi_api
# - coovi_storefront
# - coovi_admin
# - coovi_nginx
```

- [ ] Images pulled successfully
- [ ] All 5 containers running
- [ ] No restart loops (`docker ps` shows "Up X minutes", not "Restarting")

### H2: Verify Services Locally 🔴 TODO

Before SSL, test with direct IP:

```bash
# Health check
curl http://localhost:5000/api/health
# Should return: {"status":"ok","db":"connected",...}

# Storefront homepage
curl http://localhost:3000
# Should return HTML

# Admin panel
curl http://localhost:80
# Should return HTML
```

- [ ] API health check returns 200
- [ ] API connects to MongoDB successfully
- [ ] Storefront returns HTML
- [ ] Admin returns HTML

### H3: Check Logs 🔴 TODO

```bash
# API logs
docker compose logs coovi-api

# Storefront logs
docker compose logs coovi-storefront

# MongoDB logs
docker compose logs mongodb

# All logs
docker compose logs
```

- [ ] No critical errors in logs
- [ ] MongoDB started successfully
- [ ] API connected to MongoDB
- [ ] Storefront started successfully

---

## Phase I: SSL Certificates

### I1: Issue Let's Encrypt Certificates 🔴 TODO

**Important:** Temporarily disable Cloudflare proxy for HTTP-01 challenge:

1. In Cloudflare DNS, click orange cloud on all 4 records to make them grey (DNS only)
2. Wait 2-3 minutes for DNS to propagate
3. On the VPS:

```bash
cd /home/deploy/coovi

# Issue certificates for all domains
bash scripts/ssl-issue.sh you@coovi.com

# This will:
# - Issue cert for coovi.com + www.coovi.com
# - Issue cert for api.coovi.com
# - Issue cert for admin.coovi.com
```

4. After success, re-enable Cloudflare proxy (orange cloud) in DNS

- [ ] Cloudflare proxy temporarily disabled
- [ ] SSL certificates issued successfully
- [ ] Certificates saved in `/etc/letsencrypt/live/`
- [ ] Cloudflare proxy re-enabled

### I2: Restart Nginx with SSL 🔴 TODO

```bash
cd /home/deploy/coovi
docker compose restart nginx

# Check Nginx logs
docker compose logs nginx
```

- [ ] Nginx restarted
- [ ] No SSL errors in logs
- [ ] Nginx serving HTTPS

---

## Phase J: Public Access Testing

### J1: DNS & HTTPS Verification 🔴 TODO

From your local machine:

```bash
# Test each domain
curl -I https://coovi.com
curl -I https://www.coovi.com
curl -I https://api.coovi.com/api/health
curl -I https://admin.coovi.com

# All should return 200 with valid SSL
```

- [ ] `https://coovi.com` loads (200 OK)
- [ ] `https://www.coovi.com` loads (200 OK)
- [ ] `https://api.coovi.com/api/health` returns 200
- [ ] `https://admin.coovi.com` loads (200 OK)
- [ ] All use HTTPS (padlock in browser)
- [ ] SSL certificates are valid (issued by Let's Encrypt)

### J2: Browser Testing 🔴 TODO

- [ ] Open `https://coovi.com` in browser
- [ ] Homepage loads without errors
- [ ] Check browser console - no JavaScript errors
- [ ] Navigate to a product page
- [ ] Open `https://admin.coovi.com` in browser
- [ ] Admin login page loads
- [ ] Log in with admin credentials
- [ ] Admin dashboard loads

### J3: Cloudflare Real-IP Verification 🔴 TODO

```bash
# On VPS, check Nginx access logs
docker compose logs nginx | tail -20
```

Logs should show **real visitor IPs**, not Cloudflare IPs (like `172.x.x.x` or `104.x.x.x`).

If logs show Cloudflare IPs, the real-IP configuration isn't working.

- [ ] Nginx logs show real visitor IPs
- [ ] Not showing Cloudflare edge IPs

---

## Phase K: Monitoring Setup

### K1: Sentry Verification 🔴 TODO

Trigger test errors in each app:

**API:**
```bash
# Add a test route temporarily:
# app.get('/api/test-error', () => { throw new Error('Test error'); });

curl https://api.coovi.com/api/test-error
```

**Storefront:**
- Visit a non-existent page: `https://coovi.com/test-404`
- Or add a test button that throws an error

**Admin:**
- Log in and trigger a test error

Check Sentry dashboard:
- [ ] API error appears in Sentry
- [ ] Storefront error appears in Sentry
- [ ] Admin error appears in Sentry
- [ ] Stack traces are readable (source maps working)
- [ ] Errors tagged with correct environment (production)

### K2: Uptime Monitoring Verification 🔴 TODO

- [ ] Uptime monitors created for all 3 domains
- [ ] Test alert: Stop nginx temporarily: `docker stop coovi_nginx`
- [ ] Verify uptime monitor sends alert
- [ ] Restart nginx: `docker start coovi_nginx`
- [ ] Verify uptime monitor sends recovery notification

---

## Phase L: Backup Setup

### L1: Test Backup Script 🔴 TODO

```bash
cd /home/deploy/coovi

# Run backup manually
bash scripts/backup.sh

# Check backup created
ls -lh backups/
# Should see: mongo_YYYY-MM-DD_HH-MM-SS.gz

# Verify backup is not empty
ls -lh backups/*.gz
```

- [ ] Backup script runs without errors
- [ ] Backup file created
- [ ] Backup file size is reasonable (not 0 bytes)

### L2: Test Backup Restore 🔴 TODO

**On a test environment or at a safe time:**

```bash
# Restore from backup
LATEST_BACKUP=$(ls -t /home/deploy/coovi/backups/mongo_*.gz | head -1)

docker exec coovi_mongo mongorestore \
  --username coovi_admin \
  --password YOUR_MONGO_PASSWORD \
  --authenticationDatabase admin \
  --archive --gzip < "$LATEST_BACKUP"
```

- [ ] Restore command runs successfully
- [ ] Data restored correctly
- [ ] No data loss

### L3: Schedule Automated Backups 🔴 TODO

```bash
crontab -e

# Add this line (runs daily at 2 AM):
0 2 * * * /home/deploy/coovi/scripts/backup.sh >> /home/deploy/coovi/backups/backup.log 2>&1
```

- [ ] Cron job added
- [ ] Wait 24 hours and verify automatic backup created

---

## Phase M: CI/CD Testing

### M1: Test GitHub Actions Deploy 🔴 TODO

For each repo, test the CI/CD pipeline:

**coovi-api:**
```bash
# Make a small change (e.g., update a comment)
# Commit and push to master
git add .
git commit -m "Test CI/CD pipeline"
git push origin master
```

- [ ] GitHub Actions workflow triggered
- [ ] Image built successfully
- [ ] Image pushed to GHCR
- [ ] SSH deploy step succeeded
- [ ] Container restarted on VPS
- [ ] API still works after deploy

**coovi-storefront:**
- [ ] Same process as API
- [ ] Workflow builds with `NEXT_PUBLIC_*` build args
- [ ] Storefront deploys successfully

**coovi-admin:**
- [ ] Same process
- [ ] Admin deploys successfully

---

## Phase N: Performance & Load Testing

### N1: Load Test 🔴 TODO

Install Apache Bench:
```bash
# On your local machine or VPS
sudo apt install apache2-utils
```

Run load tests:
```bash
# Test storefront homepage (100 requests, 10 concurrent)
ab -n 100 -c 10 https://coovi.com/

# Test API health endpoint
ab -n 1000 -c 50 https://api.coovi.com/api/health

# Monitor server during test
ssh deploy@<VPS_IP>
watch -n 1 'docker stats --no-stream'
```

- [ ] Storefront handles 10 concurrent users without errors
- [ ] API handles 50 concurrent requests
- [ ] Memory usage stays under 1.8 GB
- [ ] Swap usage stays under 500 MB
- [ ] Response times under 500ms average

If performance issues occur, see "Performance Reality & Migration Path" in VPS_DEPLOY_PLAN.md

---

## Phase O: Documentation & Handoff

### O1: Update Documentation 🔴 TODO

- [ ] Update `VPS_DEPLOY_PLAN.md` with actual VPS IP, passwords location
- [ ] Document any deviations from the plan
- [ ] Create operational runbook: `docs/RUNBOOK.md`
  - How to check logs
  - How to restart services
  - How to deploy manually
  - Emergency contacts
  - Rollback procedures

### O2: Credentials & Access 🔴 TODO

Store in password manager:
- [ ] VPS IP address
- [ ] VPS SSH private key
- [ ] `deploy` user password
- [ ] MongoDB root username & password
- [ ] JWT_SECRET
- [ ] STOREFRONT_API_KEY
- [ ] Sentry DSNs
- [ ] Cloudflare account credentials
- [ ] GitHub PAT for GHCR
- [ ] All GitHub Secrets documented

### O3: Team Access 🔴 TODO

Grant access to relevant team members:
- [ ] VPS SSH access (add their public keys to `~/.ssh/authorized_keys`)
- [ ] GitHub repo collaborator access
- [ ] Sentry project member access
- [ ] Cloudflare account access
- [ ] AWS Lightsail console access

---

## Phase P: Go-Live

### P1: Final Pre-Launch Checks ✅

- [ ] All tests passing (API, Storefront, Admin)
- [ ] All containers running healthy
- [ ] SSL certificates valid
- [ ] DNS resolving correctly
- [ ] Monitoring and alerting working
- [ ] Backups configured and tested
- [ ] CI/CD pipelines working
- [ ] Load testing completed
- [ ] Documentation complete
- [ ] Team has access

### P2: Migration from Current Services 🔴 TODO

If migrating from existing Vercel/Render/Atlas setup:

- [ ] Export data from Atlas (if applicable)
- [ ] Import data to new MongoDB
- [ ] Update DNS to point to new VPS (already done in Phase G)
- [ ] Monitor old services for 24-48 hours
- [ ] Verify no traffic on old services
- [ ] Decommission old services

### P3: Launch Announcement 🔴 TODO

- [ ] Internal team announcement
- [ ] Monitor closely for first 24 hours
- [ ] Check Sentry for errors
- [ ] Check uptime monitor status
- [ ] Check server resources (`monitor.sh`)

---

## Post-Launch Monitoring (First Week)

### Daily Checks 🔴 TODO

**Day 1-7 after launch:**

```bash
# SSH into server
ssh deploy@<VPS_IP>

# Check system health
/home/deploy/coovi/scripts/monitor.sh

# Check for errors
docker compose logs --since 24h | grep -i error

# Check memory usage trend
free -h
```

- [ ] Day 1: All services healthy
- [ ] Day 2: All services healthy
- [ ] Day 3: All services healthy
- [ ] Day 4: All services healthy
- [ ] Day 5: All services healthy
- [ ] Day 6: All services healthy
- [ ] Day 7: All services healthy

### Weekly Review 🔴 TODO

After first week:
- [ ] Review Sentry error trends
- [ ] Review uptime monitor reports
- [ ] Review server resource usage trends
- [ ] Check swap usage patterns
- [ ] Review backup success rate
- [ ] Identify any performance bottlenecks
- [ ] Plan optimizations if needed

---

## Rollback Plan (Emergency)

If critical issues occur after deployment:

```bash
# 1. Rollback a specific service
docker pull ghcr.io/asad-404/coovi-api@sha256:<previous-digest>
docker compose up -d --no-deps coovi-api

# 2. Restore database from backup
BACKUP_FILE=/home/deploy/coovi/backups/mongo_YYYY-MM-DD.gz
docker exec coovi_mongo mongorestore --archive --gzip < "$BACKUP_FILE"

# 3. Emergency: Stop everything
docker compose down

# 4. Emergency: Revert DNS to old services (Cloudflare dashboard)
```

---

## Summary

**Total estimated time:** 6-8 hours for someone familiar with Docker/Linux, 12-16 hours for someone learning.

**Critical path:**
1. Update all 3 app repos with Docker configs (B1-B3) - 2-4 hours
2. Setup Sentry & monitoring (C1-C2) - 30 minutes
3. Configure GitHub Secrets (D2) - 30 minutes
4. Provision & setup VPS (E1-F8) - 2-3 hours
5. Deploy & test (H1-J3) - 1-2 hours
6. Setup monitoring & backups (K1-L3) - 1 hour

**Status Legend:**
- ✅ Complete
- 🟡 In Progress
- 🔴 TODO
- ⏸️ Blocked (waiting on something)

**Next immediate steps:**
1. Complete Phase B (Application Code Updates) - Start with API
2. Setup Sentry account and projects
3. Provision Lightsail instance

---

**Document version:** 1.0  
**Last updated:** 2026-11-15  
**Owner:** Asad  
**Status:** Ready for execution
