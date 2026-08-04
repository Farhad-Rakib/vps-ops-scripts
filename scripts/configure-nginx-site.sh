#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"

require_root
source_config "$CONFIG_PATH"

[[ -n "${SITE_DOMAIN:-}" ]] || die "SITE_DOMAIN is required"
[[ -n "${SITE_UPSTREAM_PORT:-}" ]] || die "SITE_UPSTREAM_PORT is required"

SITE_CONF="/etc/nginx/sites-available/${SITE_DOMAIN}.conf"
SITE_LINK="/etc/nginx/sites-enabled/${SITE_DOMAIN}.conf"
WEB_ROOT="${SITE_ROOT:-/var/www/${SITE_DOMAIN}/public}"

install -d -m 0755 "$WEB_ROOT"

server_names="$SITE_DOMAIN"
if [[ -n "${SITE_EXTRA_SERVER_NAMES:-}" ]]; then
  server_names="$server_names ${SITE_EXTRA_SERVER_NAMES}"
fi

cat > "$SITE_CONF" <<EOF
server {
    listen 80;
    listen [::]:80;
    server_name ${server_names};
    client_max_body_size ${NGINX_CLIENT_MAX_BODY_SIZE:-50m};

    location /.well-known/acme-challenge/ {
        root ${WEB_ROOT};
    }

    location / {
        proxy_pass http://127.0.0.1:${SITE_UPSTREAM_PORT};
        proxy_http_version 1.1;
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection "upgrade";
    }
}
EOF

ln -sf "$SITE_CONF" "$SITE_LINK"

nginx -t
systemctl reload nginx

if is_true "${ENABLE_SSL:-0}"; then
  [[ -n "${SSL_EMAIL:-}" ]] || die "SSL_EMAIL is required when ENABLE_SSL=1"
  certbot_args=(--nginx -d "$SITE_DOMAIN" --email "$SSL_EMAIL" --agree-tos --non-interactive --redirect)
  for extra_domain in ${SITE_EXTRA_SERVER_NAMES:-}; do
    certbot_args+=( -d "$extra_domain" )
  done
  certbot "${certbot_args[@]}"
  systemctl reload nginx
fi

log "nginx site configured for ${SITE_DOMAIN}"
