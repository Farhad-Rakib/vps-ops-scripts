#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"

require_root
source_config "$CONFIG_PATH"
ensure_apt

log "installing ufw"
apt_install ufw

ssh_port="${FIREWALL_SSH_PORT:-22}"

log "resetting firewall rules"
ufw --force reset >/dev/null

ufw default deny incoming
ufw default allow outgoing

log "allowing ssh on port ${ssh_port}"
ufw allow "${ssh_port}/tcp"

if is_true "${ENABLE_NGINX:-0}"; then
  log "allowing http (80/tcp)"
  ufw allow 80/tcp
fi

if is_true "${ENABLE_SSL:-0}"; then
  log "allowing https (443/tcp)"
  ufw allow 443/tcp
fi

# Database ports are closed by default even when the database itself is
# enabled, since the app is expected to reach it over localhost. Set the
# matching FIREWALL_ALLOW_* flag to 1 only if the database must accept
# remote connections.
if is_true "${ENABLE_POSTGRES:-0}" && is_true "${FIREWALL_ALLOW_POSTGRES:-0}"; then
  log "allowing postgres (${POSTGRES_PORT:-5432}/tcp)"
  ufw allow "${POSTGRES_PORT:-5432}/tcp"
fi

if is_true "${ENABLE_MYSQL:-0}" && is_true "${FIREWALL_ALLOW_MYSQL:-0}"; then
  log "allowing mysql (${MYSQL_PORT:-3306}/tcp)"
  ufw allow "${MYSQL_PORT:-3306}/tcp"
fi

if is_true "${ENABLE_MSSQL:-0}" && is_true "${FIREWALL_ALLOW_MSSQL:-0}"; then
  log "allowing mssql (${MSSQL_PORT:-1433}/tcp)"
  ufw allow "${MSSQL_PORT:-1433}/tcp"
fi

if is_true "${ENABLE_MONGO:-0}" && is_true "${FIREWALL_ALLOW_MONGO:-0}"; then
  log "allowing mongodb (${MONGO_PORT:-27017}/tcp)"
  ufw allow "${MONGO_PORT:-27017}/tcp"
fi

for port in ${FIREWALL_EXTRA_PORTS:-}; do
  log "allowing extra port ${port}"
  ufw allow "$port"
done

log "enabling firewall"
ufw --force enable

log "firewall configured"
ufw status verbose
