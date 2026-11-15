# COOVI Deployment — How Everything Works

> Written for someone who is new to Docker, Nginx, and Linux server management.
> Read this once before touching any config file. It explains the *why* behind every decision.

---

## The Big Picture

Right now COOVI runs across three separate cloud services:

| What | Where |
|------|-------|
| API (Express) | Render |
| Storefront (Next.js) | Vercel |
| Admin panel (React) | Vercel |
| Database (MongoDB) | Atlas |

That works, but every service has free-tier limits, sleeps after inactivity, and you pay three separate bills. The new setup moves everything to a single server, with one important addition in the middle:

```
Shoppers
    │
 Cloudflare   ← free CDN, DDoS protection, Bangladesh edge cache
    │
 AWS Lightsail VPS ($12/mo)
    │
 Nginx → API / Storefront / Admin / MongoDB
```

---

## Concept 1 — What is Docker?

Think of Docker like a **shipping container**.

Before shipping containers, loading a cargo ship was chaos — bags, boxes, animals, all different shapes and sizes. The crew had to figure out how to fit everything. A shipping container standardised the box. The ship's crew stopped caring what's inside; they only care about the box dimensions. Cranes, trucks, ships all handle the same box.

Docker does the same for software. You take your app — Node.js + your code + its dependencies — and pack it into a **container**: a standardised box that runs the same way on any machine. The server doesn't need Node installed. It doesn't need pnpm. It just runs the container.

Three words you need to know:

| Word | What it means | Real-world analogy |
|------|--------------|-------------------|
| **Image** | A frozen recipe: "this app + its dependencies + how to start it" | A cake recipe |
| **Container** | A running instance of an image | The actual cake you baked |
| **Dockerfile** | The instructions for building an image | The recipe card itself |

You can bake many cakes from one recipe. You can run many containers from one image.

---

## Concept 2 — What is Docker Compose?

Docker lets you run *one* container. Docker Compose lets you run *many containers together* as one application.

Instead of typing five separate `docker run` commands and managing networks manually, you write one file — `docker-compose.yml` — that describes all five services. Then you run one command:

```bash
docker compose up -d
```

Compose starts everything in the right order, connects them on private networks, and keeps them running.

---

## Concept 3 — What is Nginx?

Nginx (pronounced "engine-x") is a web server and **reverse proxy**.

Your VPS has one IP address. When a browser connects to `coovi.com`, it hits port 80 or 443 on that IP. But you have three different apps running: the storefront, the admin panel, and the API. How does the server know which app should answer?

Nginx reads the **domain name** in the request and routes it to the right container:

```
Browser asks for coovi.com          → Nginx → storefront container
Browser asks for admin.coovi.com    → Nginx → admin container
Browser asks for api.coovi.com      → Nginx → API container
```

Nginx is also responsible for **SSL** (the padlock in the browser). It decrypts incoming HTTPS traffic and forwards plain HTTP to your containers internally. Your Node apps never deal with SSL certificates — Nginx handles all of that.

---

## Concept 4 — What is Cloudflare?

Cloudflare sits between the internet and your server. When you set a domain's DNS through Cloudflare with the orange cloud (Proxied) enabled, every request goes to Cloudflare's nearest data centre first — including one in Dhaka. Cloudflare then forwards the request to your server.

This gives you three things for free:
- **DDoS / bot protection** — Cloudflare absorbs attacks before they reach your server.
- **Edge caching** — static assets (CSS, JS, images) served from Dhaka instead of Singapore means faster load times for Bangladeshi visitors.
- **Origin IP hidden** — attackers cannot find your real server IP by looking up the domain.

The downside is that every request now comes from a Cloudflare IP address, not the visitor's real IP. This matters for rate limiting — if Nginx sees all traffic as one IP, everyone shares the same rate limit bucket. The Nginx config fixes this (explained in the nginx.conf section).

---

## Concept 5 — What is GitHub Actions + GHCR?

**GitHub Actions** is a system that runs automated tasks when you push code. Each task is defined in a `.github/workflows/` YAML file.

**GHCR** (GitHub Container Registry) is Docker Hub but hosted by GitHub. It stores Docker images. Public images are free.

The deploy flow for each app:

```
You push code to master
        │
GitHub Actions runner (a temporary Linux VM, free)
        ├── builds the Docker image (pnpm install, tsc, next build, etc.)
        ├── pushes the image to ghcr.io/asad-404/<app>:latest
        └── SSHes into the Lightsail server
                └── docker compose pull <app>   ← downloads the new image
                    docker compose up -d        ← swaps the running container
```

**Why not build on the server?** Next.js 16 builds can spike past 2 GB of RAM. A `docker compose build` on the 2 GB Lightsail instance would be killed by the OS mid-build (this is called an OOM kill — Out Of Memory). Building on GitHub's runners avoids this entirely; the server only ever downloads a finished image.

---

## Concept 6 — Networks and Security

Docker containers can talk to each other, but only if they're on the same **network**. We create two networks:

```
[ Internet ]
      │
 [ Cloudflare edge ]
      │
  [ Nginx ]  ← only container exposed to the internet
      │
  [ web network ] ─────────────────────────────────────
      │               │                │
  [ API ]        [ Storefront ]   [ Admin ]
      │
  [ internal network ]
      │
  [ MongoDB ]
```

The API is on both networks. MongoDB is only on the `internal` network.

This means:
- Nobody on the internet can directly reach MongoDB. The only path to the database is through the API.
- Nobody can reach the API directly either — only Nginx can forward requests to it.
- If a hacker somehow compromised the storefront container, they still cannot reach MongoDB because the storefront is not on the `internal` network.

This is called **defence in depth** — multiple layers of protection.

---

## File-by-File Explanation

---

### `docker-compose.yml`

This is the master file that defines every service, network, and storage volume.

```yaml
version: "3.9"
```

The Docker Compose file format version. 3.9 is stable and widely supported.

---

#### The MongoDB service

```yaml
  mongodb:
    image: mongo:7
    mem_limit: 512m
    command: ["--wiredTigerCacheSizeGB", "0.35"]
```

`image: mongo:7` uses the official Mongo 7 image — no Dockerfile needed. `mem_limit: 512m` caps MongoDB at 512 MB of RAM. Without a cap, MongoDB's WiredTiger storage engine will claim as much RAM as it can find. On a 2 GB server shared by five containers, that would starve everything else.

`command` overrides the default command inside the container with this argument. `--wiredTigerCacheSizeGB 0.35` tells MongoDB's storage engine to use at most 350 MB for its in-memory cache. This is what keeps it inside the 512m limit — without it, MongoDB ignores the container's memory cap and gets killed by the OS anyway.

```yaml
    container_name: coovi_mongo
```

Gives the container a fixed name. Other containers connect to MongoDB using `coovi_mongo` as a hostname. Docker has built-in DNS — container names resolve to container IPs automatically.

```yaml
    restart: unless-stopped
```

If the container crashes, Docker restarts it. `unless-stopped` means "restart on crash, but not if I manually ran `docker stop`." This keeps services up after a server reboot.

```yaml
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASS}
      MONGO_INITDB_DATABASE: coovi
```

These are read by the Mongo image on **first boot only** to create the root user and the database. `${MONGO_USER}` and `${MONGO_PASS}` are placeholders — Docker Compose fills them in from your `.env.production` file.

```yaml
    volumes:
      - mongo_data:/data/db
```

MongoDB stores all data in `/data/db` inside the container. Without this line, **all your data is deleted every time the container restarts**. This mounts a **named volume** called `mongo_data` — it lives on the host machine's real disk and survives container restarts and rebuilds.

```yaml
    networks:
      - internal
```

MongoDB is only on the `internal` network — not reachable from outside, only from the API.

---

#### The API service

```yaml
  coovi-api:
    image: ghcr.io/asad-404/coovi-api:latest
```

Previously this was `build: context: ./coovi-api`. Now it's `image:` — Docker pulls this pre-built image from GitHub Container Registry instead of building it on the server. GitHub Actions builds and pushes the image; the server just downloads it.

```yaml
    mem_limit: 350m
    environment:
      - NODE_OPTIONS=--max-old-space-size=256
```

`mem_limit: 350m` caps the container at 350 MB. `NODE_OPTIONS=--max-old-space-size=256` tells Node's V8 engine to cap its own JavaScript heap at 256 MB. These two work together — the heap limit is set below the container limit so Node triggers its own garbage collector before the container's hard cap is hit. If the heap limit weren't set, Node might silently accumulate memory up to the container cap and then get killed.

```yaml
    env_file: ./coovi-api/.env.production
```

Load all variables from this file into the container. This is how `process.env.MONGODB_URI`, `process.env.JWT_SECRET`, etc. reach your running Node process. **This file is never committed to Git — you create it manually on the server.**

```yaml
    depends_on:
      - mongodb
```

Don't start the API until MongoDB has started. Mongoose retries the connection automatically, so a brief startup gap is fine.

```yaml
    networks:
      - internal
      - web
    expose:
      - "5000"
```

On both networks — needs `internal` to reach MongoDB, `web` so Nginx can reach it. `expose` makes port 5000 visible only to containers on the same network, not to the host or internet.

---

#### The Storefront service

```yaml
  coovi-storefront:
    image: ghcr.io/asad-404/coovi-storefront:latest
    mem_limit: 650m
    environment:
      - NODE_OPTIONS=--max-old-space-size=512
```

Same pattern — pre-built image from GHCR, memory cap, Node heap limit set below the cap. Next.js is the most memory-hungry service so it gets the largest allocation (650m).

```yaml
    env_file: ./coovi-storefront/.env.production
```

This file contains `STOREFRONT_API_KEY` (a server-side secret) and `NODE_ENV`. It does **not** contain `NEXT_PUBLIC_*` variables — those are baked into the JS bundle at build time by GitHub Actions and cannot be changed at runtime.

---

#### The Admin service

```yaml
  coovi-admin:
    image: ghcr.io/asad-404/coovi-admin:latest
    mem_limit: 64m
```

The admin panel is static files served by Nginx. No Node process, no env file. 64 MB is generous for Nginx serving HTML/CSS/JS. `VITE_API_URL` is baked into the bundle at build time by GitHub Actions.

---

#### The Nginx service

```yaml
  nginx:
    image: nginx:alpine
    mem_limit: 64m
    ports:
      - "80:80"
      - "443:443"
```

Nginx is the **only container that uses `ports`** — it's the only one the outside world can reach directly. `"80:80"` maps port 80 on the VPS host to port 80 inside the container. All other containers use `expose` (visible to other containers on the Docker network only).

```yaml
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/sites:/etc/nginx/conf.d:ro
      - certbot_www:/var/www/certbot:ro
      - certbot_certs:/etc/letsencrypt:ro
```

**Bind mounts** link files on your host machine directly into the container. `./nginx/nginx.conf:/etc/nginx/nginx.conf` means the config file you edit on disk IS the config file Nginx reads. `:ro` means read-only. `certbot_www` and `certbot_certs` are named volumes shared with the Certbot tool for SSL certificates.

---

#### Memory budget summary

| Container | mem_limit | Node heap cap |
|-----------|-----------|---------------|
| MongoDB   | 512m      | (WiredTiger 0.35 GB) |
| API       | 350m      | 256m |
| Storefront| 650m      | 512m |
| Admin     | 64m       | — (Nginx, not Node) |
| Nginx     | 64m       | — |
| **Total** | **1.64 GB** | |

OS + Docker daemon uses ~0.4 GB, leaving ~360 MB free RAM with a 4 GB swap file as a safety buffer.

---

### The Three Dockerfiles

A Dockerfile is a list of instructions for building a container image. Every line creates a **layer** — Docker caches each layer separately. If line 5 hasn't changed since last time, Docker reuses the cached result. This makes rebuilds fast.

---

#### `coovi-api/Dockerfile`

```dockerfile
FROM node:22-alpine AS builder
```

Start from a base image that already has Node 22 on Alpine Linux (a 5 MB Linux distro, vs Ubuntu's 100 MB+). `AS builder` names this stage — this is a **multi-stage build**. Stage 1 compiles the app; stage 2 is a clean image with only the compiled output.

```dockerfile
WORKDIR /app
RUN corepack enable && corepack prepare pnpm@latest --activate
```

Set the working directory. Enable pnpm via corepack (bundled with Node 22).

```dockerfile
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
```

**The most important Dockerfile pattern.** Copy package files first, then install. If your source code changes but `package.json` didn't, Docker reuses the cached install layer — a 60-second install becomes instant. `--frozen-lockfile` fails if the lockfile is out of sync.

```dockerfile
COPY . .
RUN pnpm build
```

Copy the rest of the source, then compile TypeScript → `dist/`.

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
```

**New stage — clean slate.** Nothing from `builder` carries over unless explicitly copied. `NODE_ENV=production` makes Express hide error details from API responses and enables production optimisations.

```dockerfile
RUN pnpm install --frozen-lockfile --prod
COPY --from=builder /app/dist ./dist
```

Install **only production dependencies** (`--prod` skips TypeScript, vitest, etc.). Copy only `dist/` from the builder stage. Final image: Node + production packages + `dist/`. No compiler, no test runner, no source files.

```dockerfile
EXPOSE 5000
CMD ["node", "dist/index.js"]
```

Document the port. Set the startup command.

---

#### `coovi-storefront/Dockerfile`

Same pattern as the API with extra build-time variables:

```dockerfile
ARG DOCKER_BUILD=true
ENV DOCKER_BUILD=$DOCKER_BUILD

ARG NEXT_PUBLIC_API_URL
ARG NEXT_PUBLIC_SITE_URL
ARG NEXT_PUBLIC_WHATSAPP_NUMBER
ENV NEXT_PUBLIC_API_URL=$NEXT_PUBLIC_API_URL
ENV NEXT_PUBLIC_SITE_URL=$NEXT_PUBLIC_SITE_URL
ENV NEXT_PUBLIC_WHATSAPP_NUMBER=$NEXT_PUBLIC_WHATSAPP_NUMBER
```

`ARG` declares a build-time variable — it exists only during `docker build`, not at runtime. `ENV` promotes it to a real environment variable so `process.env.NEXT_PUBLIC_*` works during the build.

**Why are these in the Dockerfile and not in `.env.production`?** Because `NEXT_PUBLIC_*` variables in Next.js are baked into the JavaScript bundle at build time. By the time the container is running, the bundle is already compiled — changing an env var at runtime has no effect. These values must exist when `next build` runs, which is during the Docker build step on GitHub Actions. GitHub Actions reads them from GitHub Secrets and passes them as `--build-arg`.

The runner stage is slimmer than the API:

```dockerfile
FROM node:22-alpine AS runner
COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static     ./.next/static
COPY --from=builder /app/public           ./public
CMD ["node", "server.js"]
```

No `pnpm install` here. When Next.js builds in **standalone mode** (triggered by `DOCKER_BUILD=true` → `output: 'standalone'` in `next.config.ts`), it bundles its own minimal `node_modules` inside `.next/standalone/`. Three things copied: the server bundle, the static assets, and the public folder. Final image is ~150 MB instead of ~1 GB.

---

#### `coovi-admin/Dockerfile`

```dockerfile
ARG VITE_API_URL
ENV VITE_API_URL=$VITE_API_URL
```

Same pattern — `VITE_*` variables are baked into the bundle by Vite at build time. They must arrive as build arguments from GitHub Actions.

```dockerfile
FROM nginx:alpine AS runner
COPY --from=builder /app/dist /usr/share/nginx/html
COPY nginx-spa.conf /etc/nginx/conf.d/default.conf
CMD ["nginx", "-g", "daemon off;"]
```

The runner uses `nginx:alpine` (not Node) because the admin panel is pure static files after build. No server process. `daemon off` keeps Nginx in the foreground — Docker needs the main process to stay there or it assumes the container stopped.

---

### `coovi-admin/nginx-spa.conf`

The Nginx config inside the admin container (separate from the main reverse-proxy Nginx).

```nginx
location / {
  try_files $uri $uri/ /index.html;
}
```

The **SPA fix**. Without it, refreshing `admin.coovi.com/orders` returns 404 — there's no `orders.html` on disk. React Router handles that URL in JavaScript. `try_files` tries the exact file, then tries it as a directory, then falls back to `index.html`. React boots, reads the URL, renders the right page.

```nginx
location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {
  expires 1y;
  add_header Cache-Control "public, immutable";
}
```

Vite adds a content hash to every filename (e.g. `main.a3f9b2.js`). The name changes whenever content changes, so it's safe to cache these files for a year. Returning visitors load the admin panel from their browser cache instantly.

---

### `nginx/nginx.conf`

The master Nginx config — global settings that apply to all five site configs.

```nginx
user nobody;
worker_processes auto;
```

Run as `nobody` (low-privilege user, not root). `auto` creates one worker per CPU core.

```nginx
  set_real_ip_from 173.245.48.0/20;
  set_real_ip_from 103.21.244.0/22;
  ... (23 ranges total)
  real_ip_header CF-Connecting-IP;
```

**The Cloudflare real-IP fix.** This is new compared to a standard Nginx config.

When Cloudflare proxies a request, `$remote_addr` (the connecting IP Nginx sees) is a Cloudflare edge server IP, not the visitor's real IP. This matters because:
- The API uses `$remote_addr` for rate limiting — if all traffic looks like one IP, one visitor could accidentally exhaust the rate limit for everyone.
- Access logs would show Cloudflare IPs instead of visitor IPs, making debugging impossible.

`set_real_ip_from` tells Nginx: "if a request comes from one of these IP ranges, trust the `CF-Connecting-IP` header it added and use that as `$remote_addr` instead." The 23 ranges listed are all of Cloudflare's published IPv4 and IPv6 address ranges. `real_ip_header CF-Connecting-IP` names the header to read the real IP from.

After these lines, `$remote_addr` throughout the rest of Nginx (and in the Express app via `X-Real-IP`) is the actual visitor's IP.

```nginx
  log_format main '$remote_addr ...';
  access_log /var/log/nginx/access.log main;
```

Access log format. With the real-IP fix above, `$remote_addr` now logs real visitor IPs.

```nginx
  gzip on;
  gzip_types text/plain text/css application/json application/javascript ...;
  client_max_body_size 20m;
```

Compress responses (a 100 KB JS file compresses to ~30 KB). Allow up to 20 MB request bodies for photo uploads in the admin panel.

```nginx
  include /etc/nginx/conf.d/*.conf;
```

Load all `.conf` files from that folder — `api.conf`, `storefront.conf`, `admin.conf`.

---

### `nginx/sites/api.conf` (storefront + admin follow the same pattern)

Each domain has two `server` blocks.

**Block 1 — HTTP (port 80)**

```nginx
server {
  listen 80;
  server_name api.coovi.com;

  location /.well-known/acme-challenge/ {
    root /var/www/certbot;
  }

  location / {
    return 301 https://$host$request_uri;
  }
}
```

`server_name` is how Nginx picks the right block — all three `.conf` files listen on port 80 but each has a different domain. The `/.well-known/acme-challenge/` block is for Let's Encrypt's domain verification step (see ssl-issue.sh). Everything else redirects to HTTPS.

**Block 2 — HTTPS (port 443)**

```nginx
  ssl_certificate     /etc/letsencrypt/live/api.coovi.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/api.coovi.com/privkey.pem;
  ssl_protocols       TLSv1.2 TLSv1.3;
```

The SSL certificate and key files written by Let's Encrypt. Only TLS 1.2 and 1.3 — older versions have known vulnerabilities.

```nginx
  location / {
    proxy_pass         http://coovi_api:5000;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
  }
```

**The reverse proxy.** Forwards all HTTPS traffic to `http://coovi_api:5000`. `coovi_api` is the Docker container name — Docker resolves it to the container's private IP. The `proxy_set_header` lines forward the visitor's real IP (already restored by the Cloudflare real-IP fix) and whether the original request was HTTP or HTTPS. This is what `TRUST_PROXY=1` in the API's env refers to.

---

### GitHub Actions workflows (`.github/workflows/deploy.yml`)

Each of the three app repos has a `deploy.yml`. They all follow the same four-step structure.

---

#### Trigger and concurrency

```yaml
on:
  push:
    branches: [master]

concurrency:
  group: deploy-api
  cancel-in-progress: true
```

Runs only when code is pushed to `master` — not on pull requests. `concurrency` ensures if two pushes happen close together, the second one cancels the first mid-flight instead of two deploys running simultaneously and potentially corrupting the running containers.

---

#### Permissions

```yaml
permissions:
  contents: read
  packages: write
```

`packages: write` grants the workflow permission to push to `ghcr.io` under your GitHub account. Without it, the push step would fail with a 403. `contents: read` is the minimum to check out the code. No other permissions are granted — following least-privilege.

---

#### Step 1 — Checkout

```yaml
- uses: actions/checkout@v4
```

Clones the repository onto the runner. Everything after this can read the source files.

---

#### Step 2 — Log in to GHCR

```yaml
- uses: docker/login-action@v3
  with:
    registry: ghcr.io
    username: ${{ github.actor }}
    password: ${{ secrets.GITHUB_TOKEN }}
```

Authenticates with GitHub Container Registry. `github.actor` is the GitHub username that triggered the push. `secrets.GITHUB_TOKEN` is a temporary token GitHub automatically creates for each workflow run — no manual setup needed. It expires when the run ends.

---

#### Step 3 — Set up Docker Buildx

```yaml
- uses: docker/setup-buildx-action@v3
```

Installs BuildKit, the modern Docker build engine. Required for the registry layer cache to work. BuildKit can also build for multiple CPU architectures simultaneously, though we only target `linux/amd64` here.

---

#### Step 4 — Build and push image

```yaml
- uses: docker/build-push-action@v6
  with:
    context: .
    push: true
    tags: ghcr.io/asad-404/coovi-api:latest
    cache-from: type=registry,ref=ghcr.io/asad-404/coovi-api:buildcache
    cache-to:   type=registry,ref=ghcr.io/asad-404/coovi-api:buildcache,mode=max
```

`context: .` means use the entire repo as the Docker build context (where `COPY` looks for files). `push: true` pushes to GHCR after a successful build. `tags` is the image name and tag — `:latest` is the standard name for the most recent version.

`cache-from` and `cache-to` store Docker layer cache in GHCR. Without this, every build re-downloads all packages and re-compiles everything from scratch. With it, unchanged layers are skipped. A fresh build takes ~3 minutes; a cached build (only source files changed, `package.json` unchanged) takes ~30 seconds.

---

#### Storefront and admin — build-args

The storefront and admin workflows add `build-args`:

```yaml
# storefront
build-args: |
  DOCKER_BUILD=true
  NEXT_PUBLIC_API_URL=${{ secrets.NEXT_PUBLIC_API_URL }}
  NEXT_PUBLIC_SITE_URL=${{ secrets.NEXT_PUBLIC_SITE_URL }}
  NEXT_PUBLIC_WHATSAPP_NUMBER=${{ secrets.NEXT_PUBLIC_WHATSAPP_NUMBER }}

# admin
build-args: |
  VITE_API_URL=${{ secrets.VITE_API_URL }}
```

`${{ secrets.NEXT_PUBLIC_API_URL }}` reads a secret from GitHub → Repository Settings → Secrets and variables → Actions. The secret is encrypted, never shown in logs, and only exposed to workflows. It's passed to the Docker build as an `ARG` (declared in the Dockerfile), which becomes an `ENV` so `next build` / `vite build` can read it.

**Why GitHub Secrets and not `.env.production` on the server?** Because these variables are baked into the JavaScript bundle at build time. By the time the container is running, the bundle is already compiled — there's nothing to read from `.env.production`. The only moment they can be injected is during `docker build`.

---

#### Step 5 — SSH deploy

```yaml
- uses: appleboy/ssh-action@v1
  with:
    host:     ${{ secrets.VPS_HOST }}
    username: deploy
    key:      ${{ secrets.VPS_SSH_KEY }}
    script: |
      /home/deploy/coovi/scripts/deploy.sh api
```

SSHes into the Lightsail server and runs the deploy script. `VPS_HOST` is the server's public IPv4. `VPS_SSH_KEY` is the private key for the `deploy` user (the matching public key is in `~/.ssh/authorized_keys` on the server). The connection is encrypted — nobody between GitHub and the server can read the key.

---

### `scripts/deploy.sh`

```bash
COMPOSE="docker compose -f $ROOT/docker-compose.yml"

pull_restart() {
  $COMPOSE pull "$1"
  $COMPOSE up -d --no-deps "$1"
}
```

Previously this script ran `docker compose build` (compiled on the server). Now it runs `docker compose pull` — downloads the pre-built image from GHCR. The `pull` command only downloads if the image has changed; it's fast when nothing changed.

`up -d --no-deps "$1"` starts the named service in the background without restarting the other services it depends on. If you're deploying only the API, MongoDB and Nginx stay running.

```bash
docker image prune -f
```

Each `pull` downloads a new image layer. The old layers become "dangling" — not used by any container. This deletes them so old images don't fill the 60 GB disk over time.

---

### `scripts/backup.sh`

```bash
source /home/deploy/coovi/.env.production
```

`source` reads a file and executes it as shell code, importing its variable definitions. After this line, `$MONGO_USER` and `$MONGO_PASS` are available as shell variables.

```bash
docker exec coovi_mongo mongodump \
  --archive --gzip > "$FILE"
```

`docker exec` runs a command inside the already-running container. `mongodump --archive --gzip` exports the entire database as a single compressed binary stream, redirected to a file on the host disk.

```bash
find "$BACKUP_DIR" -name "mongo_*.gz" -mtime +14 -delete
```

Delete backups older than 14 days. Without this, backups accumulate and eventually fill the disk.

---

### `scripts/ssl-issue.sh`

```bash
docker run --rm \
  -v "$ROOT/certbot_certs:/etc/letsencrypt" \
  -v "$ROOT/certbot_www:/var/www/certbot" \
  certbot/certbot certonly --webroot ...
```

Runs the official Certbot container. `--rm` deletes the container when done. The two `-v` flags mount the same named volumes Nginx uses — Certbot writes certs there, Nginx reads them from the same location. `--webroot` verification works by writing a temporary file to `/var/www/certbot/` and Let's Encrypt fetches it over HTTP (this is why the Nginx HTTP block has the `/.well-known/acme-challenge/` route).

> **Cloudflare note:** Cloudflare must be in "DNS only" (grey cloud, not orange) while running this script, or the HTTP challenge traffic won't reach your server. Switch back to Proxied (orange) after the certs are issued.

---

### `coovi-storefront/next.config.ts` — the two changes

**Change 1 — standalone output:**

```typescript
const isDockerBuild = process.env.DOCKER_BUILD === "true";

const nextConfig: NextConfig = {
  ...(isDockerBuild && { output: "standalone" }),
```

`...(condition && { key: value })` is a JavaScript spread trick: if `isDockerBuild` is false, spreading `false` into an object does nothing; if true, it adds `output: "standalone"` to the config. Vercel builds never set `DOCKER_BUILD`, so Vercel is completely unaffected.

**Change 2 — image optimisation off:**

```typescript
  images: {
    unoptimized: true,
    remotePatterns: [ ... ]
  }
```

By default, Next.js resizes and converts images on the fly using server-side CPU when a browser requests an `<Image>` component. On a 2-vCPU Lightsail server shared by five containers, that's expensive. Setting `unoptimized: true` tells Next.js to serve images as-is without processing them. The trade-off is intentional: **Cloudinary** handles all image optimisation instead (`f_auto`, `q_auto`, `w_400`, `w_1000` transforms), serving already-optimised images from its own CDN. The Lightsail container never touches image data.

---

### `.env.production.example` files

Templates — never committed with real values. The real `.env.production` files are created manually on the server.

**Root `.env.production.example`** — just `MONGO_USER` and `MONGO_PASS` for the Docker Compose `${...}` substitutions.

**`coovi-api/.env.production.example`** — key entries:

```
MONGODB_URI=mongodb://coovi_user:CHANGE_ME@coovi_mongo:27017/coovi?authSource=admin
```

`coovi_mongo` resolves to the MongoDB container's internal IP via Docker DNS. `authSource=admin` authenticates against the admin database where the root user was created.

```
TRUST_PROXY=1
```

Tells Express to trust forwarded headers from Nginx. Without this, rate limiting uses Nginx's internal IP for all requests — everyone shares the same rate limit bucket. With `TRUST_PROXY=1`, Express reads the real IP that Nginx (already corrected by the Cloudflare real-IP fix) forwarded.

---

## How Everything Connects — Tracing One Request

A customer in Dhaka visits `coovi.com/saree`:

1. **DNS** resolves `coovi.com` to a Cloudflare edge server IP (not the VPS IP — it's hidden).
2. **Cloudflare (Dhaka edge)** receives the request. If the page is cached, it serves it immediately from Dhaka — no trip to Singapore. If not cached, it forwards to the VPS.
3. **Nginx** (port 443, `storefront.conf`) receives the request with `CF-Connecting-IP: <real visitor IP>`. The real-IP fix restores `$remote_addr`. Nginx forwards to `http://coovi_storefront:3000/saree`.
4. **Storefront container** renders the page. Product images are `<img>` tags pointing at `res.cloudinary.com` — the browser fetches them from Cloudinary's CDN, not the Lightsail server.
5. **Nginx** forwards the HTML back through Cloudflare back to the browser.
6. **Cloudflare** caches the response for future visitors.

When the customer places an order, the storefront calls `https://api.coovi.com/api/orders`. That goes: Cloudflare → Nginx → API container → MongoDB (internal network). MongoDB is never reachable from any other path.

When you push code to `master` in `coovi-api`, GitHub Actions builds the image on GitHub's servers, pushes it to GHCR, then SSHes into the VPS and runs `docker compose pull coovi-api && docker compose up -d --no-deps coovi-api`. The API container is replaced in a few seconds with no downtime for MongoDB or Nginx.

---

## Summary Table

| File | Repo | What it does |
|------|------|--------------|
| `docker-compose.yml` | coovi-docs | All 5 containers, mem_limits, GHCR images, networks, volumes |
| `nginx/nginx.conf` | coovi-docs | Global settings + Cloudflare real-IP restoration |
| `nginx/sites/api.conf` | coovi-docs | Routes `api.coovi.com` → API:5000 |
| `nginx/sites/storefront.conf` | coovi-docs | Routes `coovi.com`/`www` → storefront:3000 |
| `nginx/sites/admin.conf` | coovi-docs | Routes `admin.coovi.com` → admin:80 |
| `scripts/deploy.sh` | coovi-docs | `docker compose pull` + restart one service or all |
| `scripts/backup.sh` | coovi-docs | Nightly mongodump, 14-day retention |
| `scripts/ssl-issue.sh` | coovi-docs | Let's Encrypt cert issue + auto-renew cron |
| `.env.production.example` | coovi-docs | Template for Mongo root credentials |
| `Dockerfile` | coovi-api | Multi-stage: TS compile → prod-only Node image |
| `.dockerignore` | coovi-api | Keeps secrets and junk out of image |
| `.env.production.example` | coovi-api | Template for all API production variables |
| `.github/workflows/deploy.yml` | coovi-api | Build → GHCR push → SSH deploy on master push |
| `Dockerfile` | coovi-storefront | Multi-stage: Next standalone build → slim Node image |
| `.dockerignore` | coovi-storefront | Same |
| `.env.production.example` | coovi-storefront | Template for storefront runtime variables |
| `.github/workflows/deploy.yml` | coovi-storefront | Build with NEXT_PUBLIC_* build-args → GHCR → SSH |
| `next.config.ts` | coovi-storefront | `output:'standalone'` + `images.unoptimized:true` |
| `Dockerfile` | coovi-admin | Multi-stage: Vite build → nginx:alpine static image |
| `.dockerignore` | coovi-admin | Same |
| `.env.production.example` | coovi-admin | Template (VITE_* vars go to GitHub Secrets, not here) |
| `nginx-spa.conf` | coovi-admin | SPA fallback + 1-year asset cache inside admin container |
| `.github/workflows/deploy.yml` | coovi-admin | Build with VITE_API_URL build-arg → GHCR → SSH |
