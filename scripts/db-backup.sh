#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"
source_config "$CONFIG_PATH"

BACKUP_OUTPUT_DIR="${BACKUP_OUTPUT_DIR:-/var/backups/db}"
BACKUP_KEEP_DAYS="${BACKUP_KEEP_DAYS:-7}"
mkdir -p "$BACKUP_OUTPUT_DIR"

timestamp="$(date '+%Y%m%d_%H%M%S')"

case "${BACKUP_TYPE:-postgres}" in
  postgres)
    [[ -n "${BACKUP_NAME:-}" ]] || die "BACKUP_NAME is required for postgres backups"
    export PGPASSWORD="${BACKUP_PASSWORD:-}"
    pg_dump -h "${BACKUP_HOST:-127.0.0.1}" -p "${BACKUP_PORT:-5432}" -U "${BACKUP_USER:-postgres}" -Fc "${BACKUP_NAME}" >"${BACKUP_OUTPUT_DIR}/${BACKUP_NAME}_${timestamp}.dump"
    ;;
  mysql)
    [[ -n "${BACKUP_NAME:-}" ]] || die "BACKUP_NAME is required for mysql backups"
    mysqldump -h "${BACKUP_HOST:-127.0.0.1}" -P "${BACKUP_PORT:-3306}" -u "${BACKUP_USER:-root}" ${BACKUP_PASSWORD:+-p"${BACKUP_PASSWORD}"} --single-transaction --routines --events "${BACKUP_NAME}" >"${BACKUP_OUTPUT_DIR}/${BACKUP_NAME}_${timestamp}.sql"
    ;;
  mssql)
    [[ -n "${BACKUP_NAME:-}" ]] || die "BACKUP_NAME is required for mssql backups"
    [[ -n "${MSSQL_SA_PASSWORD:-}" ]] || die "MSSQL_SA_PASSWORD is required for mssql backups"
    backup_file="${BACKUP_OUTPUT_DIR}/${BACKUP_NAME}_${timestamp}.bak"
    sqlcmd -S "${BACKUP_HOST:-127.0.0.1},${BACKUP_PORT:-1433}" -U sa -P "$MSSQL_SA_PASSWORD" -Q "BACKUP DATABASE [${BACKUP_NAME}] TO DISK = N'${backup_file}' WITH INIT, COMPRESSION"
    ;;
  mongo)
    [[ -n "${BACKUP_NAME:-}" ]] || die "BACKUP_NAME is required for mongo backups"
    mongo_uri="mongodb://${BACKUP_HOST:-127.0.0.1}:${BACKUP_PORT:-27017}/${BACKUP_NAME}"
    if [[ -n "${MONGO_USER:-}" && -n "${MONGO_PASSWORD:-}" ]]; then
      mongo_uri="mongodb://${MONGO_USER}:${MONGO_PASSWORD}@${BACKUP_HOST:-127.0.0.1}:${BACKUP_PORT:-27017}/${BACKUP_NAME}?authSource=${MONGO_AUTH_DB:-admin}"
    fi
    mongodump --uri="$mongo_uri" --archive="${BACKUP_OUTPUT_DIR}/${BACKUP_NAME}_${timestamp}.archive"
    ;;
  *)
    die "unsupported BACKUP_TYPE: ${BACKUP_TYPE:-}"
    ;;
esac

find "$BACKUP_OUTPUT_DIR" -type f -mtime "+${BACKUP_KEEP_DAYS}" -delete
log "backup complete in ${BACKUP_OUTPUT_DIR}"
