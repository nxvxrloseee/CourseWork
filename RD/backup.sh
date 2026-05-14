#!/bin/bash
# =============================================================
# RepairDesk — PostgreSQL backup script
# Usage: bash backup.sh [backup_dir]
# Default backup dir: ./backups
# =============================================================

set -euo pipefail

CONTAINER="rd-postgres"
DB_NAME="repairdesk"
DB_USER="postgres"
BACKUP_DIR="${1:-./backups}"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
FILENAME="repairdesk_${TIMESTAMP}.sql.gz"
KEEP_DAYS=30

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Check container is running
if ! docker ps --format '{{.Names}}' | grep -q "^${CONTAINER}$"; then
  echo "[ERROR] Container '${CONTAINER}' is not running."
  exit 1
fi

echo "[INFO] Starting backup of '${DB_NAME}' from container '${CONTAINER}'..."

# Run pg_dump inside container, compress on host
docker exec "$CONTAINER" \
  pg_dump -U "$DB_USER" -d "$DB_NAME" --no-owner --no-acl \
  | gzip > "${BACKUP_DIR}/${FILENAME}"

SIZE=$(du -h "${BACKUP_DIR}/${FILENAME}" | cut -f1)
echo "[OK] Backup saved: ${BACKUP_DIR}/${FILENAME} (${SIZE})"

# Remove backups older than KEEP_DAYS
DELETED=$(find "$BACKUP_DIR" -name "repairdesk_*.sql.gz" -mtime +"$KEEP_DAYS" -print -delete | wc -l)
if [ "$DELETED" -gt 0 ]; then
  echo "[INFO] Removed ${DELETED} backup(s) older than ${KEEP_DAYS} days."
fi

echo "[DONE] Backup complete."
