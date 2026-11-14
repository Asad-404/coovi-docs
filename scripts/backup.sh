#!/bin/bash
# Daily MongoDB backup. Run via cron:
#   0 2 * * * /home/deploy/coovi/scripts/backup.sh >> /home/deploy/coovi/backups/backup.log 2>&1
set -e

BACKUP_DIR="/home/deploy/coovi/backups"
DATE=$(date +%Y-%m-%d_%H-%M)
FILE="$BACKUP_DIR/mongo_$DATE.gz"

# Load Mongo credentials from the root .env.production
source /home/deploy/coovi/.env.production

echo "[$(date)] Starting backup..."

docker exec coovi_mongo mongodump \
  --username "$MONGO_USER" \
  --password "$MONGO_PASS" \
  --authenticationDatabase admin \
  --db coovi \
  --archive \
  --gzip > "$FILE"

echo "[$(date)] Backup written: $FILE ($(du -h "$FILE" | cut -f1))"

# Keep only the last 14 days
find "$BACKUP_DIR" -name "mongo_*.gz" -mtime +14 -delete
echo "[$(date)] Old backups pruned. Done."
