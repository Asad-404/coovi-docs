#!/bin/bash
# Pull latest pre-built images from ghcr.io and restart one service or all.
# Images are built by GitHub Actions and pushed to GHCR — no on-server builds.
# Usage:
#   ./scripts/deploy.sh api
#   ./scripts/deploy.sh storefront
#   ./scripts/deploy.sh admin
#   ./scripts/deploy.sh all
set -e

SERVICE=${1:-all}
ROOT="/home/deploy/coovi"
COMPOSE="docker compose -f $ROOT/docker-compose.yml"

pull_restart() {
  echo "→ Pulling $1..."
  $COMPOSE pull "$1"
  $COMPOSE up -d --no-deps "$1"
}

case $SERVICE in
  api)        pull_restart coovi-api        ;;
  storefront) pull_restart coovi-storefront ;;
  admin)      pull_restart coovi-admin      ;;
  all)
    $COMPOSE pull
    $COMPOSE up -d
    ;;
  *)
    echo "Usage: $0 api | storefront | admin | all"
    exit 1
    ;;
esac

docker image prune -f
echo "✓ Deploy done: $SERVICE"
