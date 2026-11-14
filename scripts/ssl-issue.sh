#!/bin/bash
# Issue Let's Encrypt certificates for all four COOVI domains.
# Run once after DNS A records are pointing at this server.
# Usage: bash scripts/ssl-issue.sh your@email.com
set -e

EMAIL=${1:?"Usage: $0 <email>"}
ROOT="/home/deploy/coovi"

certbot_args=(
  --webroot
  -w /var/www/certbot
  --email "$EMAIL"
  --agree-tos
  --no-eff-email
  --non-interactive
)

echo "→ Issuing cert for coovi.com and www.coovi.com..."
docker run --rm \
  -v "$ROOT/certbot_certs:/etc/letsencrypt" \
  -v "$ROOT/certbot_www:/var/www/certbot" \
  certbot/certbot certonly "${certbot_args[@]}" \
  -d coovi.com -d www.coovi.com

echo "→ Issuing cert for api.coovi.com..."
docker run --rm \
  -v "$ROOT/certbot_certs:/etc/letsencrypt" \
  -v "$ROOT/certbot_www:/var/www/certbot" \
  certbot/certbot certonly "${certbot_args[@]}" \
  -d api.coovi.com

echo "→ Issuing cert for admin.coovi.com..."
docker run --rm \
  -v "$ROOT/certbot_certs:/etc/letsencrypt" \
  -v "$ROOT/certbot_www:/var/www/certbot" \
  certbot/certbot certonly "${certbot_args[@]}" \
  -d admin.coovi.com

echo "→ Reloading Nginx..."
docker exec coovi_nginx nginx -s reload

# Add auto-renew cron if not already present
CRON_LINE="0 3 * * * docker run --rm -v $ROOT/certbot_certs:/etc/letsencrypt -v $ROOT/certbot_www:/var/www/certbot certbot/certbot renew --quiet && docker exec coovi_nginx nginx -s reload"
( crontab -l 2>/dev/null | grep -v "certbot renew"; echo "$CRON_LINE" ) | crontab -

echo "✓ SSL certs issued and auto-renew cron installed."
