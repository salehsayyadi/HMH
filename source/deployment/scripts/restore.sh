#!/bin/bash
set -euo pipefail

if [ "$#" -lt 1 ]; then
    echo "Usage: $0 <path_to_backup_file.sql.gz>"
    exit 1
fi

BACKUP_FILE="$1"

if [ ! -f "${BACKUP_FILE}" ]; then
    echo "Error: Backup file ${BACKUP_FILE} does not exist."
    exit 1
fi

# Verify checksum if available
if [ -f "${BACKUP_FILE}.sha256" ]; then
    echo "Verifying checksum..."
    sha256sum -c "${BACKUP_FILE}.sha256"
fi

echo "WARNING: Restoring will overwrite existing tables in database ${MYSQL_DATABASE}!"
read -p "Type 'RESTORE-CONFIRM' to proceed: " CONFIRM

if [ "${CONFIRM}" != "RESTORE-CONFIRM" ]; then
    echo "Aborted."
    exit 0
fi

echo "Restoring database from ${BACKUP_FILE}..."
gunzip -c "${BACKUP_FILE}" | mysql \
  --host="${MYSQL_HOST}" \
  --port="${MYSQL_PORT}" \
  --user="${MYSQL_USER}" \
  --password="${MYSQL_PASSWORD}" \
  --default-character-set=utf8mb4 \
  "${MYSQL_DATABASE}"

echo "Database restored successfully."
