#!/bin/bash
# Rebuild and restart one service or all.
# Usage:
#   ./scripts/deploy.sh api
#   ./scripts/deploy.sh storefront
#   ./scripts/deploy.sh admin
#   ./scripts/deploy.sh all
set -e

SERVICE=${1:-all}
ROOT="/home/deploy/coovi"

pull() {
  echo "→ Pulling $1..."
  git -C "$ROOT/$1" pull origin main
}

rebuild() {
  echo "→ Rebuilding $1..."
  docker compose -f "$ROOT/docker-compose.yml" build "$1"
  docker compose -f "$ROOT/docker-compose.yml" up -d --no-deps "$1"
}

case $SERVICE in
  api)
    pull coovi-api
    rebuild coovi-api
    ;;
  storefront)
    pull coovi-storefront
    rebuild coovi-storefront
    ;;
  admin)
    pull coovi-admin
    rebuild coovi-admin
    ;;
  all)
    pull coovi-api
    pull coovi-storefront
    pull coovi-admin
    docker compose -f "$ROOT/docker-compose.yml" build
    docker compose -f "$ROOT/docker-compose.yml" up -d
    ;;
  *)
    echo "Usage: $0 api | storefront | admin | all"
    exit 1
    ;;
esac

docker image prune -f
echo "✓ Deploy done: $SERVICE"
