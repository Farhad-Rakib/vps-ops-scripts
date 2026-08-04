#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"
DOMAIN="${2:-}"
UPSTREAM_PORT="${3:-}"

require_root
source_config "$CONFIG_PATH"

[[ -n "$DOMAIN" ]] || die "usage: sudo bash scripts/deploy-site.sh [config.sh] <domain> <upstream-port>"

if [[ -z "$UPSTREAM_PORT" ]]; then
  UPSTREAM_PORT="${SITE_UPSTREAM_PORT:-}"
fi

[[ -n "$UPSTREAM_PORT" ]] || die "upstream port is required"

TEMP_CONFIG="$(mktemp)"
cleanup() {
  rm -f "$TEMP_CONFIG"
}
trap cleanup EXIT

{
  printf 'ENABLE_SSL=%q\n' "${ENABLE_SSL:-0}"
  printf 'SITE_DOMAIN=%q\n' "$DOMAIN"
  printf 'SITE_UPSTREAM_PORT=%q\n' "$UPSTREAM_PORT"
  printf 'SITE_EXTRA_SERVER_NAMES=%q\n' "${SITE_EXTRA_SERVER_NAMES:-}"
  printf 'SITE_ROOT=%q\n' "${SITE_ROOT:-/var/www/${DOMAIN}/public}"
  printf 'NGINX_CLIENT_MAX_BODY_SIZE=%q\n' "${NGINX_CLIENT_MAX_BODY_SIZE:-50m}"
  printf 'SSL_EMAIL=%q\n' "${SSL_EMAIL:-}"
} >"$TEMP_CONFIG"

bash "$SCRIPT_DIR/configure-nginx-site.sh" "$TEMP_CONFIG"

log "site deployed for ${DOMAIN}"
