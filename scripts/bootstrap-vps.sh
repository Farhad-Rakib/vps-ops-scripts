#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"

require_root
source_config "$CONFIG_PATH"
ensure_apt
apt_update

log "installing base packages"
apt_install curl ca-certificates gnupg lsb-release unzip tar jq software-properties-common

if is_true "${ENABLE_NGINX:-0}"; then
  log "installing nginx"
  apt_install nginx
  systemctl enable nginx
fi

if is_true "${ENABLE_SSL:-0}"; then
  log "installing certbot"
  apt_install certbot python3-certbot-nginx
fi

if is_true "${ENABLE_DOCKER:-0}"; then
  log "installing docker"
  apt_install docker.io docker-compose-plugin
  systemctl enable docker
fi

if is_true "${ENABLE_POSTGRES:-0}"; then
  log "installing postgresql"
  apt_install postgresql postgresql-contrib
  systemctl enable postgresql
fi

if is_true "${ENABLE_MYSQL:-0}"; then
  log "installing mysql"
  apt_install mysql-server
  systemctl enable mysql
fi

if is_true "${ENABLE_MONGO:-0}"; then
  log "installing mongodb"
  os_info="$(detect_os)"
  os_id="${os_info%%:*}"
  os_codename="${os_info##*:}"
  [[ "$os_id" == "ubuntu" || "$os_id" == "debian" ]] || die "mongodb repository setup is only wired for ubuntu and debian"
  if [[ ! -f /usr/share/keyrings/mongodb-server-7.0.gpg ]]; then
    curl -fsSL https://pgp.mongodb.com/server-7.0.asc | gpg --dearmor -o /usr/share/keyrings/mongodb-server-7.0.gpg
  fi
  cat > /etc/apt/sources.list.d/mongodb-org-7.0.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/mongodb-server-7.0.gpg] https://repo.mongodb.org/apt/$os_id $os_codename/mongodb-org/7.0 multiverse
EOF
  apt_update
  apt_install mongodb-org mongodb-database-tools
  systemctl enable mongod
fi

if is_true "${ENABLE_MSSQL:-0}"; then
  log "installing mssql"
  [[ -n "${MSSQL_SA_PASSWORD:-}" ]] || die "MSSQL_SA_PASSWORD is required when ENABLE_MSSQL=1"
  os_info="$(detect_os)"
  os_id="${os_info%%:*}"
  os_codename="${os_info##*:}"
  [[ "$os_id" == "ubuntu" || "$os_id" == "debian" ]] || die "mssql repository setup is only wired for ubuntu and debian"
  if [[ ! -f /usr/share/keyrings/microsoft-prod.gpg ]]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
  fi
  cat > /etc/apt/sources.list.d/microsoft-prod.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/$os_id/$os_codename/prod $os_codename main
EOF
  apt_update
  ACCEPT_EULA=Y MSSQL_SA_PASSWORD="$MSSQL_SA_PASSWORD" apt_install mssql-server mssql-tools18 unixodbc-dev
  systemctl enable mssql-server
fi

log "bootstrap complete"
