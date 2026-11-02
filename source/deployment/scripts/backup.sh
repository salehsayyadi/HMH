#!/bin/bash
set -euo pipefail

BACKUP_DIR="/backups"
TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/hmh_backup_${TIMESTAMP}.sql.gz"
CHECKSUM_FILE="${BACKUP_FILE}.sha256"

mkdir -p "${BACKUP_DIR}/daily" "${BACKUP_DIR}/weekly" "${BACKUP_DIR}/monthly"

echo "[$(date)] Starting MySQL backup for ${MYSQL_DATABASE}..."

# Execute atomic mysqldump with single transaction for InnoDB
mysqldump \
  --host="${MYSQL_HOST}" \
  --port="${MYSQL_PORT}" \
  --user="${MYSQL_USER}" \
  --password="${MYSQL_PASSWORD}" \
  --single-transaction \
  --quick \
  --routines \
  --triggers \
  --events \
  --default-character-set=utf8mb4 \
  "${MYSQL_DATABASE}" | gzip -9 > "${BACKUP_FILE}"

# Verify integrity & generate SHA256 checksum per Part 38
sha256sum "${BACKUP_FILE}" > "${CHECKSUM_FILE}"

# Test gzip integrity
gzip -t "${BACKUP_FILE}"

echo "[$(date)] Backup completed successfully: ${BACKUP_FILE}"

# Copy to daily folder
cp "${BACKUP_FILE}" "${BACKUP_DIR}/daily/"
cp "${CHECKSUM_FILE}" "${BACKUP_DIR}/daily/"

# If Sunday (0), copy to weekly
if [ "$(date +%u)" -eq 7 ]; then
    cp "${BACKUP_FILE}" "${BACKUP_DIR}/weekly/"
fi

# If 1st day of month, copy to monthly
if [ "$(date +%d)" -eq "01" ]; then
    cp "${BACKUP_FILE}" "${BACKUP_DIR}/monthly/"
fi

# Retention policy per Part 38:
# Daily: delete older than 30 days
find "${BACKUP_DIR}/daily" -type f -name "*.sql.gz*" -mtime +30 -delete
# Weekly: delete older than 56 days (8 weeks)
find "${BACKUP_DIR}/weekly" -type f -name "*.sql.gz*" -mtime +56 -delete
# Monthly: delete older than 365 days (12 months)
find "${BACKUP_DIR}/monthly" -type f -name "*.sql.gz*" -mtime +365 -delete

echo "[$(date)] Backup retention cleanup completed."
