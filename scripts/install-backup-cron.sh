#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"

source_config "$CONFIG_PATH"

command -v crontab >/dev/null 2>&1 || die "crontab command not found"

config_abs_path="$(cd "$(dirname "$CONFIG_PATH")" && pwd)/$(basename "$CONFIG_PATH")"
backup_script_path="$SCRIPT_DIR/db-backup.sh"
minute="${BACKUP_CRON_MINUTE:-0}"
hour="${BACKUP_CRON_HOUR:-2}"
day_of_month="${BACKUP_CRON_DAY_OF_MONTH:-*}"
month="${BACKUP_CRON_MONTH:-*}"
day_of_week="${BACKUP_CRON_DAY_OF_WEEK:-*}"
log_file="${BACKUP_CRON_LOG_FILE:-/var/log/db-backup.log}"
marker="# shell-scripts:db-backup config=${config_abs_path}"

cron_command="/bin/bash $(printf '%q' "$backup_script_path") $(printf '%q' "$config_abs_path") >> $(printf '%q' "$log_file") 2>&1"
cron_entry="${minute} ${hour} ${day_of_month} ${month} ${day_of_week} ${cron_command} ${marker}"

existing_crontab="$(crontab -l 2>/dev/null || true)"
filtered_crontab="$(printf '%s\n' "$existing_crontab" | grep -vF "$marker" || true)"

{
  if [[ -n "$filtered_crontab" ]]; then
    printf '%s\n' "$filtered_crontab"
  fi
  printf '%s\n' "$cron_entry"
} | crontab -

log "installed backup cron entry for ${config_abs_path}"
