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

That works, but every service has free-tier limits, sleeps after inactivity, and you pay three separate bills. Moving to a VPS means **one machine runs everything**. The challenge: how do you run five different programs on one Linux server without them conflicting, and how do you manage them together?

The answer is **Docker**. Everything in this repository supports Docker.

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

## Concept 4 — Networks and Security

Docker containers can talk to each other, but only if they're on the same **network**. We create two networks:

```
[ Internet ]
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
services:
  mongodb:
    image: mongo:7
```

`services` lists every container. `mongodb` uses the official Mongo 7 image from Docker Hub — no Dockerfile needed. Docker downloads it automatically.

```yaml
    container_name: coovi_mongo
```

Gives the container a fixed, predictable name. Other containers can connect to MongoDB using `coovi_mongo` as a hostname. Docker has built-in DNS — container names resolve to container IPs automatically. Without this, Docker assigns a random name on every boot.

```yaml
    restart: unless-stopped
```

If the container crashes, Docker restarts it. `unless-stopped` means "restart on crash, but not if I manually ran `docker stop`." This keeps your services up after a server reboot.

```yaml
    environment:
      MONGO_INITDB_ROOT_USERNAME: ${MONGO_USER}
      MONGO_INITDB_ROOT_PASSWORD: ${MONGO_PASS}
      MONGO_INITDB_DATABASE: coovi
```

These environment variables are read by the Mongo image on **first boot only** to create the root user and the database. `${MONGO_USER}` and `${MONGO_PASS}` are placeholders — Docker Compose fills them in from your `.env.production` file in the same directory.

```yaml
    volumes:
      - mongo_data:/data/db
```

MongoDB stores all data in `/data/db` inside the container. Without this line, **all your data is deleted every time the container restarts** (containers are stateless by default). This line mounts a **named volume** called `mongo_data` onto that path. The volume lives on the host machine's real disk and survives container restarts, rebuilds, and even `docker compose down`.

```yaml
    networks:
      - internal
```

MongoDB is only on the `internal` network — not reachable from the outside, only from the API.

---

#### The API service

```yaml
  coovi-api:
    build:
      context: ./coovi-api
      dockerfile: Dockerfile
```

Instead of `image:` (which downloads a pre-built image), `build:` tells Compose to build the image from a Dockerfile. `context` is the folder it uses as the root for `COPY` commands. `dockerfile` names the Dockerfile to use.

```yaml
    env_file: ./coovi-api/.env.production
```

Load all variables from this file into the container. This is how `process.env.MONGODB_URI`, `process.env.JWT_SECRET`, etc. reach your running Node process. **This file is never committed to Git — you create it manually on the server.**

```yaml
    depends_on:
      - mongodb
```

Don't start the API until the MongoDB container has started. Note: "started" means the process launched, not that Mongo is fully ready. For safety, Mongoose retries the connection automatically on startup.

```yaml
    networks:
      - internal
      - web
    expose:
      - "5000"
```

The API is on **both** networks — it needs `internal` to reach MongoDB, and `web` so Nginx can forward requests to it.

`expose` makes port 5000 visible to other containers on the same network, but **not to the host machine or the internet**. If you wanted to open it to the outside world you'd use `ports:` instead. We don't — only Nginx should ever talk to the API directly.

---

#### The Storefront service

```yaml
  coovi-storefront:
    build:
      args:
        DOCKER_BUILD: "true"
```

This passes a **build argument** into the Dockerfile. The Dockerfile passes it to `next build`, which makes Next.js produce a "standalone" output — a minimal bundle that only needs `node server.js` to run. More on this in the Dockerfile section. Vercel never sets this variable, so Vercel deployments are unaffected.

---

#### The Admin service

```yaml
  coovi-admin:
    build:
      context: ./coovi-admin
      dockerfile: Dockerfile
    container_name: coovi_admin
    restart: unless-stopped
    networks:
      - web
    expose:
      - "80"
```

The admin panel is a static site — after Vite builds it, there's no Node process. The container is just Nginx serving HTML/CSS/JS files. It only needs the `web` network (so the main Nginx proxy can reach it) and no env file (there are no server-side secrets; the API URL is baked in at build time).

---

#### The Nginx service

```yaml
  nginx:
    image: nginx:alpine
    container_name: coovi_nginx
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
```

Nginx is the **only container that uses `ports`**. Format is `"host_port:container_port"`. This maps port 80 on the VPS to port 80 inside the Nginx container. When a browser connects to your server's IP on port 80, the traffic arrives here.

```yaml
    volumes:
      - ./nginx/nginx.conf:/etc/nginx/nginx.conf:ro
      - ./nginx/sites:/etc/nginx/conf.d:ro
      - certbot_www:/var/www/certbot:ro
      - certbot_certs:/etc/letsencrypt:ro
```

These are **bind mounts** — they link files on your host machine directly into the container. `./nginx/nginx.conf:/etc/nginx/nginx.conf` takes the config file from your project folder and makes it the config file Nginx reads. `:ro` means read-only. If you edit the config file on the host, it's immediately reflected inside the container (after an `nginx -s reload`).

`certbot_www` and `certbot_certs` are the named volumes that Let's Encrypt uses. They're shared between Nginx (which needs to serve the challenge files and the SSL certs) and the Certbot tool (which writes them).

---

#### Networks and Volumes declarations

```yaml
networks:
  web:
  internal:

volumes:
  mongo_data:
  certbot_www:
  certbot_certs:
```

You must declare networks and volumes before using them. These empty declarations tell Compose to create them with default settings when you first run `docker compose up`.

---

### The Three Dockerfiles

A Dockerfile is a list of instructions for building a container image. Every line creates a **layer** — Docker caches each layer separately. If line 5 hasn't changed since last time, Docker reuses the cached result instead of re-running it. This makes rebuilds fast.

---

#### `coovi-api/Dockerfile`

```dockerfile
FROM node:22-alpine AS builder
```

`FROM` means "start from this base image." You don't install Linux from scratch — you start from an image that already has Node 22 and Alpine Linux (a tiny 5 MB Linux distro, vs Ubuntu's 100 MB+). `AS builder` names this stage "builder."

**Why two stages?** This is called a **multi-stage build**. Stage 1 (`builder`) installs everything needed to compile the app: TypeScript compiler, type definitions, test tools. Stage 2 (`runner`) is a fresh, clean image that gets only the compiled output. The final image has no compiler, no test runner — just what's needed to run.

```dockerfile
WORKDIR /app
```

All following commands run from `/app` inside the container. Like `cd /app` and staying there forever.

```dockerfile
RUN corepack enable && corepack prepare pnpm@latest --activate
```

`RUN` executes a shell command during the build. Node 22 includes **corepack**, a tool for managing package managers. This activates pnpm. The `&&` chains two commands into one layer (fewer layers = smaller image).

```dockerfile
COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile
```

**The most important Dockerfile pattern.** Copy *only* the package files first, then install. If your source code changes but `package.json` didn't, Docker reuses the cached `pnpm install` layer — skipping re-downloading all packages. This turns a 60-second rebuild into a 5-second one.

`--frozen-lockfile` means "if `pnpm-lock.yaml` doesn't match `package.json`, fail." Prevents surprise version changes in production.

```dockerfile
COPY . .
RUN pnpm build
```

Now copy the rest of the source, then run `pnpm build` which runs `tsc` (TypeScript compiler). This turns `src/*.ts` files into `dist/*.js` files.

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production
```

**New stage — clean slate.** Nothing from `builder` carries over unless you explicitly copy it. `ENV` sets an environment variable permanently in the image. `NODE_ENV=production` makes Express enable production optimisations and hide detailed error messages from API responses.

```dockerfile
RUN corepack enable && corepack prepare pnpm@latest --activate

COPY package.json pnpm-lock.yaml ./
RUN pnpm install --frozen-lockfile --prod
```

Install pnpm again (clean stage), then install **only production dependencies** (`--prod`). This skips TypeScript, vitest, type definitions — everything only needed to build or test.

```dockerfile
COPY --from=builder /app/dist ./dist
```

Copy only the compiled JavaScript from the `builder` stage. `--from=builder` reaches into the previous stage. The final image contains: Node.js, production packages, and `dist/`. Nothing else.

```dockerfile
EXPOSE 5000
CMD ["node", "dist/index.js"]
```

`EXPOSE` documents which port this container listens on. It doesn't open the port — Docker Compose handles that. It's documentation.

`CMD` is what runs when the container starts. This starts the Express server.

---

#### `coovi-storefront/Dockerfile`

Same pattern as the API, with two differences specific to Next.js.

```dockerfile
ARG DOCKER_BUILD=true
ENV DOCKER_BUILD=$DOCKER_BUILD
```

`ARG` is a build-time variable (exists only during `docker build`, not at runtime). It's set to `true` by Docker Compose (via `args: DOCKER_BUILD: "true"`). `ENV` promotes it into an environment variable so `next.config.ts` can read it via `process.env.DOCKER_BUILD`.

The runner stage is different from the API:

```dockerfile
FROM node:22-alpine AS runner
WORKDIR /app
ENV NODE_ENV=production

COPY --from=builder /app/.next/standalone ./
COPY --from=builder /app/.next/static     ./.next/static
COPY --from=builder /app/public           ./public

EXPOSE 3000
CMD ["node", "server.js"]
```

No `pnpm install` here. When Next.js builds in **standalone mode**, it bundles its own minimal `node_modules` inside `.next/standalone/`. So the runner just copies three things:

| What | Why |
|------|-----|
| `.next/standalone/` | The server + its bundled dependencies |
| `.next/static/` | CSS, JavaScript, images for the browser |
| `public/` | Fonts, favicons, robots.txt |

`server.js` is a file Next.js generates inside `.next/standalone/`. It's a plain Node HTTP server — no Next.js tooling required to run it. The final image is ~150 MB instead of ~1 GB.

---

#### `coovi-admin/Dockerfile`

The admin panel compiles to pure static files — HTML, CSS, JavaScript. There's no server process. You just need something to serve the files over HTTP.

```dockerfile
FROM node:22-alpine AS builder
# ... same install + build pattern ...
RUN pnpm build   # outputs to dist/
```

```dockerfile
FROM nginx:alpine AS runner
```

The runner stage doesn't even use Node. It uses **Nginx** as a static file server. The image is under 10 MB.

```dockerfile
COPY --from=builder /app/dist /usr/share/nginx/html
```

Copy the compiled files into Nginx's default web root.

```dockerfile
COPY nginx-spa.conf /etc/nginx/conf.d/default.conf
```

Replace Nginx's default config with our custom one (explained next).

```dockerfile
CMD ["nginx", "-g", "daemon off;"]
```

`daemon off` keeps Nginx in the foreground. Docker needs the main process to stay in the foreground — if it goes to the background, Docker thinks the container stopped.

---

### `coovi-admin/nginx-spa.conf`

This config is for the Nginx *inside* the admin container. It only controls how the admin panel's static files are served.

```nginx
server {
  listen 80;
  root /usr/share/nginx/html;
  index index.html;
```

Listen on port 80. Serve files from `/usr/share/nginx/html`. When someone visits `/`, serve `index.html`.

```nginx
  location / {
    try_files $uri $uri/ /index.html;
  }
```

This is the **SPA fix**. Without it, refreshing `admin.coovi.com/orders` would return a 404 — there's no `orders.html` file on disk. React Router handles that URL in JavaScript.

`try_files` says: try the exact file → try it as a directory → if neither exists, serve `index.html`. React then boots up, reads the URL from the browser, and renders the right page.

```nginx
  location ~* \.(js|css|png|jpg|jpeg|gif|svg|ico|woff2?)$ {
    expires 1y;
    add_header Cache-Control "public, immutable";
  }
```

`~*` means "match this regex, case-insensitive." This matches any file ending in `.js`, `.css`, images, or fonts.

Vite adds a **content hash** to every filename when it builds (e.g. `main.a3f9b2.js`). The filename changes whenever the content changes. This means it's safe to tell browsers to cache these files for **one year** (`expires 1y`) and never re-check them (`immutable`). Returning visitors load the admin panel almost instantly from their browser cache.

---

### `nginx/nginx.conf`

The master Nginx config — global settings that apply before any per-site config.

```nginx
user nobody;
worker_processes auto;
```

Run Nginx worker processes as `nobody` (a low-privilege user, not root). `auto` creates one worker per CPU core — on a 2-vCPU server, two workers.

```nginx
events {
  worker_connections 1024;
}
```

Each worker handles up to 1024 simultaneous connections. With 2 workers: 2048 total.

```nginx
http {
  include /etc/nginx/mime.types;
  default_type application/octet-stream;
```

`mime.types` maps file extensions to Content-Type headers. Without it, Nginx sends everything as a binary download and browsers refuse to run JavaScript or apply CSS.

```nginx
  log_format main '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for"';

  access_log /var/log/nginx/access.log main;
```

Defines a log format and applies it. Every request produces one line:
`123.45.67.89 - - [14/Nov/2026] "GET /api/products HTTP/1.1" 200 1452 "-" "Mozilla/5.0..."`

This is how you debug problems and see what people are requesting.

```nginx
  sendfile on;
  tcp_nopush on;
  keepalive_timeout 65;
```

Performance settings. `sendfile` lets the OS transfer files from disk to network without an extra memory copy — faster for static files. `tcp_nopush` batches TCP packets. `keepalive_timeout 65` keeps connections open 65 seconds so the browser reuses them for multiple requests.

```nginx
  gzip on;
  gzip_types text/plain text/css application/json application/javascript ...;
```

Compress responses before sending. A 100 KB JavaScript file typically compresses to ~30 KB — pages load roughly 3× faster on slow connections.

```nginx
  client_max_body_size 20m;
```

Maximum request body size. This matters for the admin panel's photo upload — without it, Nginx would reject uploads larger than the default 1 MB.

```nginx
  include /etc/nginx/conf.d/*.conf;
```

Load all `.conf` files from that folder. That's where `api.conf`, `storefront.conf`, and `admin.conf` live.

---

### `nginx/sites/api.conf` (and storefront + admin follow the same pattern)

Each site has two `server` blocks.

---

#### Block 1 — HTTP (port 80)

```nginx
server {
  listen 80;
  server_name api.coovi.com;
```

`server_name` is how Nginx tells domains apart. All three `.conf` files listen on port 80, but each has a different `server_name`. Nginx picks the right block by matching the domain in the incoming request.

```nginx
  location /.well-known/acme-challenge/ {
    root /var/www/certbot;
  }
```

This is for **Let's Encrypt domain verification**. When you request an SSL certificate, Let's Encrypt verifies you control the domain by placing a temporary file at this path and fetching it over HTTP. `root /var/www/certbot` points to the shared volume where Certbot wrote that file. Without this exception, the HTTP→HTTPS redirect below would intercept the verification request and Let's Encrypt would fail.

```nginx
  location / {
    return 301 https://$host$request_uri;
  }
```

Redirect everything else to HTTPS. 301 is a permanent redirect — browsers and search engines remember it. `$host` is the domain, `$request_uri` is the path and query string. So `http://api.coovi.com/api/products?limit=10` becomes `https://api.coovi.com/api/products?limit=10`.

---

#### Block 2 — HTTPS (port 443)

```nginx
server {
  listen 443 ssl;
  http2 on;
  server_name api.coovi.com;
```

`listen 443 ssl` accepts encrypted HTTPS connections. `http2 on` enables HTTP/2 — a faster protocol that can send multiple requests over one connection simultaneously.

```nginx
  ssl_certificate     /etc/letsencrypt/live/api.coovi.com/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/api.coovi.com/privkey.pem;
  ssl_protocols       TLSv1.2 TLSv1.3;
  ssl_prefer_server_ciphers on;
```

`fullchain.pem` is the SSL certificate (proves this server is really `api.coovi.com`). `privkey.pem` is the private key (used for encryption). These files are written by Let's Encrypt/Certbot into the shared volume.

`TLSv1.2 TLSv1.3` only allows modern encryption — TLS 1.0 and 1.1 are outdated and have known vulnerabilities.

```nginx
  location / {
    proxy_pass http://coovi_api:5000;
```

**This is the reverse proxy.** All HTTPS requests to `api.coovi.com` are forwarded to `http://coovi_api:5000` — the API container. `coovi_api` is the container name, Docker resolves it to the container's private IP on the `web` network.

```nginx
    proxy_http_version 1.1;
    proxy_set_header   Upgrade $http_upgrade;
    proxy_set_header   Connection 'upgrade';
```

These three lines enable WebSocket support — in case the API ever uses WebSockets (long-lived real-time connections), these headers allow the protocol upgrade.

```nginx
    proxy_set_header   Host $host;
    proxy_set_header   X-Real-IP $remote_addr;
    proxy_set_header   X-Forwarded-For $proxy_add_x_forwarded_for;
    proxy_set_header   X-Forwarded-Proto $scheme;
```

When Nginx forwards requests, it adds these headers. Without them, the API would see every single request coming from Nginx's internal IP (`172.x.x.x`) instead of the visitor's real IP.

| Header | What it carries |
|--------|-----------------|
| `Host` | The original domain (`api.coovi.com`) |
| `X-Real-IP` | The visitor's real IP address |
| `X-Forwarded-For` | Full chain of IPs if there are multiple proxies |
| `X-Forwarded-Proto` | Whether the original request was `http` or `https` |

This is why `TRUST_PROXY=1` is in the API's production env — it tells Express to read these forwarded headers from Nginx.

**storefront.conf** has an extra server block to redirect `www.coovi.com` → `coovi.com`. This is called canonicalisation — it ensures all traffic and search engine ranking goes to one URL, not split across two.

**admin.conf** doesn't have the WebSocket headers because the admin panel is static files — no long-lived connections needed.

---

### `coovi-storefront/next.config.ts` — the one line we changed

```typescript
const isDockerBuild = process.env.DOCKER_BUILD === "true";

const nextConfig: NextConfig = {
  ...(isDockerBuild && { output: "standalone" }),
```

`process.env.DOCKER_BUILD` reads the environment variable set by the Dockerfile.

`...(condition && { key: value })` is a JavaScript trick:
- If `isDockerBuild` is `false`: `false && { output: "standalone" }` → `false` → spreading `false` into an object does nothing. Config is unchanged.
- If `isDockerBuild` is `true`: `true && { output: "standalone" }` → `{ output: "standalone" }` → spreads into the config object as if you wrote `output: "standalone"` directly.

Result: Vercel builds are unaffected. Docker builds get the standalone output.

---

### `.dockerignore` files

Same concept as `.gitignore` but for `COPY` commands inside a Dockerfile.

```
node_modules
```

Never copy `node_modules` from your Windows development machine into the image. The Dockerfile installs them fresh inside the container. If you copied them, they'd contain Windows binaries that won't run on Linux.

```
.env
.env.*
!.env.example
!.env.production.example
```

**Critical.** If `.env` got copied into the image, your secrets — database password, JWT secret — would be baked in and readable by anyone who pulls the image. The `!` prefix means "except this file" — the example templates are safe because they contain no real values.

```
dist
```

Don't copy your locally-compiled output. The Dockerfile compiles fresh inside the container for the target Linux architecture.

```
.git
coverage
*.log
```

No need for Git history, test coverage reports, or log files in a production image. Skipping them keeps images smaller.

---

### `scripts/deploy.sh`

```bash
#!/bin/bash
```

The **shebang line**. Every shell script starts with this. It tells the OS to run this file with Bash (the shell). Without it, the OS doesn't know how to interpret the file.

```bash
set -e
```

If any command fails (exits with error code), **stop the script immediately**. Without this, the script would continue even after a build failure — potentially restarting a broken container while the old working one is already stopped.

```bash
SERVICE=${1:-all}
```

`$1` is the first argument you pass when running the script. `./scripts/deploy.sh api` → `$1` is `api`. `:-all` is a default — if you run `./scripts/deploy.sh` with no argument, `SERVICE` becomes `all`.

```bash
ROOT="/home/deploy/coovi"
```

A variable for the project path. Used throughout the script so you only change it in one place if the path ever moves.

```bash
pull() {
  git -C "$ROOT/$1" pull origin main
}
```

A reusable function. `git -C path` runs Git in a specific directory without having to `cd` there. This pulls the latest code from GitHub.

```bash
rebuild() {
  docker compose -f "$ROOT/docker-compose.yml" build "$1"
  docker compose -f "$ROOT/docker-compose.yml" up -d --no-deps "$1"
}
```

`build "$1"` rebuilds the image for that one service only.
`up -d` starts it in the background (`-d` = detached — the command returns immediately).
`--no-deps` means "don't restart the other services it depends on." If you're only deploying the API, MongoDB and Nginx should not restart.

```bash
case $SERVICE in
  api)        pull coovi-api;        rebuild coovi-api        ;;
  storefront) pull coovi-storefront; rebuild coovi-storefront ;;
  admin)      pull coovi-admin;      rebuild coovi-admin      ;;
  all)
    pull coovi-api; pull coovi-storefront; pull coovi-admin
    docker compose -f "$ROOT/docker-compose.yml" build
    docker compose -f "$ROOT/docker-compose.yml" up -d
    ;;
  *)
    echo "Usage: $0 api | storefront | admin | all"
    exit 1
    ;;
esac
```

`case` is Bash's switch statement. The `*` case is the fallback — if you type an unknown service name, it prints usage and exits with code 1 (error code, signals failure).

```bash
docker image prune -f
```

After every deploy, old image layers accumulate on disk. Each rebuild creates new layers and the old ones become "dangling" — not used by any container. This deletes them. `-f` means "don't ask for confirmation." Left unchecked over months, dangling images can fill the disk.

---

### `scripts/backup.sh`

```bash
DATE=$(date +%Y-%m-%d_%H-%M)
FILE="$BACKUP_DIR/mongo_$DATE.gz"
```

`$(...)` runs a command and captures its output as a string. `date +%Y-%m-%d_%H-%M` outputs something like `2026-11-14_02-00`. The backup file will be named `mongo_2026-11-14_02-00.gz`.

```bash
source /home/deploy/coovi/.env.production
```

`source` reads a file and runs it as shell code. After this line, `$MONGO_USER` and `$MONGO_PASS` are available as shell variables — read from the production env file, never hardcoded in the script.

```bash
docker exec coovi_mongo mongodump \
  --username "$MONGO_USER" \
  --password "$MONGO_PASS" \
  --authenticationDatabase admin \
  --db coovi \
  --archive \
  --gzip > "$FILE"
```

`docker exec coovi_mongo` runs a command inside the already-running `coovi_mongo` container. `mongodump` is MongoDB's official backup tool — it exports the entire database. `--archive` outputs one single binary stream instead of many files. `--gzip` compresses it. `> "$FILE"` redirects the output stream to a file on the host machine's disk.

```bash
find "$BACKUP_DIR" -name "mongo_*.gz" -mtime +14 -delete
```

Delete old backups. `-name "mongo_*.gz"` matches backup files. `-mtime +14` matches files older than 14 days. `-delete` deletes them. Without this, backups accumulate forever and eventually fill the disk.

---

### `scripts/ssl-issue.sh`

```bash
EMAIL=${1:?"Usage: $0 <email>"}
```

`?` after the colon means "this argument is **required** — if missing, print this message and stop." Different from `:-` which provides a default.

```bash
certbot_args=(
  --webroot
  -w /var/www/certbot
  --email "$EMAIL"
  --agree-tos
  --no-eff-email
  --non-interactive
)
```

A Bash array storing arguments reused for each domain. `--webroot` is the verification method — Certbot writes a temporary file to `/var/www/certbot/` and Let's Encrypt's servers fetch it over HTTP to verify you own the domain. This is why the Nginx config has the `/.well-known/acme-challenge/` block.

```bash
docker run --rm \
  -v "$ROOT/certbot_certs:/etc/letsencrypt" \
  -v "$ROOT/certbot_www:/var/www/certbot" \
  certbot/certbot certonly "${certbot_args[@]}" \
  -d coovi.com -d www.coovi.com
```

Runs the official Certbot Docker container. `--rm` deletes the container as soon as it finishes. The two `-v` flags mount the same named volumes that Nginx uses — so when Certbot writes the cert files, Nginx can immediately read them. `certonly` just gets the cert without touching any server config. `-d` specifies the domains to cover.

```bash
( crontab -l 2>/dev/null | grep -v "certbot renew"; echo "$CRON_LINE" ) | crontab -
```

This installs the auto-renew cron job. Breaking it down step by step:

| Part | What it does |
|------|--------------|
| `crontab -l` | List existing cron jobs |
| `2>/dev/null` | Discard the error if no cron jobs exist yet |
| `grep -v "certbot renew"` | Remove any existing certbot line (prevents duplicates if script runs twice) |
| `echo "$CRON_LINE"` | Add the new renewal command |
| `\| crontab -` | Feed the whole thing back to `crontab -` which replaces the cron file |

The cron line itself (`0 3 * * *`) means "run at 3:00 AM every day." Let's Encrypt certs expire after 90 days; this renews them automatically when they're 30 days from expiry.

---

### `.env.production.example` files

These are **templates**, not real config. The real `.env.production` files are created manually on the server and never committed to Git.

**Root `.env.production.example`** — the two variables Docker Compose needs to create the MongoDB root user, fed in as `${MONGO_USER}` and `${MONGO_PASS}`.

**`coovi-api/.env.production.example`** — the most detailed one. Key entries:

```
MONGODB_URI=mongodb://coovi_user:CHANGE_ME@coovi_mongo:27017/coovi?authSource=admin
```

`coovi_mongo` is the container name — Docker resolves it to the container's internal IP. `authSource=admin` means authenticate against the `admin` database (where the root user was created by `MONGO_INITDB_ROOT_USERNAME`).

```
TRUST_PROXY=1
```

Tells Express to trust the `X-Forwarded-For` and `X-Real-IP` headers forwarded by Nginx. Without this, rate limiting would use Nginx's internal IP for all requests — meaning everyone shares the same rate limit bucket and one person's requests could block everyone else.

```
NODE_ENV=production
```

Switches Express into production mode: hides detailed error stack traces from API responses (so attackers can't see your folder structure), enables response caching headers, and activates production optimisations in many packages.

---

## How Everything Connects — Tracing One Request

A customer visits `coovi.com/saree`:

1. **DNS** resolves `coovi.com` to your VPS IP address.
2. **Browser** sends `GET /saree HTTP/1.1` to port 80 of that IP.
3. **Nginx** (port 80, `storefront.conf` block 1) sees the request is for `coovi.com`, checks it's not a Let's Encrypt challenge, and returns a 301 redirect to `https://coovi.com/saree`.
4. **Browser** follows the redirect to port 443.
5. **Nginx** (port 443, `storefront.conf` block 2) decrypts the SSL connection using the Let's Encrypt certificate, then forwards the plain HTTP request to `http://coovi_storefront:3000/saree` on the internal `web` Docker network. It adds `X-Real-IP` and `X-Forwarded-Proto: https` headers.
6. **Storefront container** (Next.js `server.js`) receives the request, renders the saree listing page (possibly fetching product data from `https://api.coovi.com/api/products`), and sends back HTML.
7. **Nginx** forwards the HTML back to the browser.
8. **Browser** renders the page. The HTML references `/saree.css` and `/_next/static/chunks/page.js` — the browser fetches those too, all going through Nginx → storefront container.

The admin making a login request to `admin.coovi.com` follows the same path, but Nginx routes it to the admin container instead. The API call to `api.coovi.com/api/login` goes to the API container, which connects to MongoDB on the `internal` network.

---

## Summary Table

| File | Lives in | What it does |
|------|----------|--------------|
| `docker-compose.yml` | root | Defines and runs all 5 containers together |
| `nginx/nginx.conf` | root | Global Nginx settings (logging, compression, mime types) |
| `nginx/sites/api.conf` | root | Routes `api.coovi.com` to the API container |
| `nginx/sites/storefront.conf` | root | Routes `coovi.com` to the storefront container |
| `nginx/sites/admin.conf` | root | Routes `admin.coovi.com` to the admin container |
| `scripts/deploy.sh` | root | Pulls latest code + rebuilds + restarts a service |
| `scripts/backup.sh` | root | Dumps MongoDB to a compressed file, keeps 14 days |
| `scripts/ssl-issue.sh` | root | Gets SSL certs from Let's Encrypt, sets up auto-renew |
| `.env.production.example` | root | Template for MongoDB credentials |
| `coovi-api/Dockerfile` | coovi-api | Builds the API into a container image |
| `coovi-api/.dockerignore` | coovi-api | Prevents secrets and junk entering the image |
| `coovi-api/.env.production.example` | coovi-api | Template for all API production variables |
| `coovi-storefront/Dockerfile` | coovi-storefront | Builds the Next.js storefront (standalone mode) |
| `coovi-storefront/.dockerignore` | coovi-storefront | Same as API |
| `coovi-storefront/.env.production.example` | coovi-storefront | Template for storefront production variables |
| `coovi-storefront/next.config.ts` | coovi-storefront | Adds `output:'standalone'` when building in Docker |
| `coovi-admin/Dockerfile` | coovi-admin | Builds the admin panel into a static Nginx image |
| `coovi-admin/.dockerignore` | coovi-admin | Same as API |
| `coovi-admin/nginx-spa.conf` | coovi-admin | Config for the Nginx inside the admin container |
| `coovi-admin/.env.production.example` | coovi-admin | Template for admin production variables |
