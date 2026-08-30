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

if is_true "${ENABLE_PHP:-0}"; then
  php_version="${PHP_VERSION:-8.3}"
  log "installing php ${php_version}"
  apt_install ca-certificates apt-transport-https software-properties-common
  add-apt-repository -y ppa:ondrej/php
  apt_update
  apt_install \
    "php${php_version}" "php${php_version}-fpm" "php${php_version}-cli" \
    "php${php_version}-common" "php${php_version}-mysql" "php${php_version}-pgsql" \
    "php${php_version}-xml" "php${php_version}-mbstring" "php${php_version}-curl" \
    "php${php_version}-zip"
  systemctl enable "php${php_version}-fpm"
fi

if is_true "${ENABLE_NODEJS:-0}"; then
  node_version="${NODE_VERSION:-20}"
  log "installing node.js ${node_version}"
  curl -fsSL "https://deb.nodesource.com/setup_${node_version}.x" | bash -
  apt_install nodejs
fi

if is_true "${ENABLE_DJANGO:-0}"; then
  log "installing python3 for django"
  apt_install python3 python3-venv python3-pip

  if [[ -n "${DJANGO_PROJECT_DIR:-}" ]]; then
    venv_name="${DJANGO_VENV_NAME:-venv}"
    venv_path="${DJANGO_PROJECT_DIR}/${venv_name}"
    install -d -m 0755 "$DJANGO_PROJECT_DIR"
    if [[ ! -d "$venv_path" ]]; then
      log "creating virtualenv at ${venv_path}"
      python3 -m venv "$venv_path"
    fi

    requirements_file="${DJANGO_PROJECT_DIR}/requirements.txt"
    if [[ -f "$requirements_file" ]]; then
      log "installing requirements.txt into ${venv_path}"
      "${venv_path}/bin/pip" install --upgrade pip
      "${venv_path}/bin/pip" install -r "$requirements_file"
    fi
  fi
fi

if is_true "${ENABLE_DOTNET:-0}"; then
  dotnet_version="${DOTNET_VERSION:-8.0}"
  log "installing dotnet sdk ${dotnet_version}"
  os_info="$(detect_os)"
  os_id="${os_info%%:*}"
  os_codename="${os_info##*:}"
  [[ "$os_id" == "ubuntu" || "$os_id" == "debian" ]] || die "dotnet repository setup is only wired for ubuntu and debian"
  if [[ ! -f /usr/share/keyrings/microsoft-prod.gpg ]]; then
    curl -fsSL https://packages.microsoft.com/keys/microsoft.asc | gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
  fi
  if [[ ! -f /etc/apt/sources.list.d/microsoft-prod.list ]]; then
    cat > /etc/apt/sources.list.d/microsoft-prod.list <<EOF
deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://packages.microsoft.com/$os_id/$os_codename/prod $os_codename main
EOF
  fi
  apt_update
  apt_install "dotnet-sdk-${dotnet_version}"
fi

if is_true "${ENABLE_LARAVEL:-0}"; then
  is_true "${ENABLE_PHP:-0}" || die "ENABLE_LARAVEL requires ENABLE_PHP=1"
  command -v php >/dev/null 2>&1 || die "php CLI was not found; enable ENABLE_PHP or install php first"

  if ! command -v composer >/dev/null 2>&1; then
    log "installing composer"
    curl -fsSL https://getcomposer.org/installer -o /tmp/composer-setup.php
    php /tmp/composer-setup.php --install-dir=/usr/local/bin --filename=composer
    rm -f /tmp/composer-setup.php
  fi

  if [[ -n "${LARAVEL_PROJECT_DIR:-}" ]]; then
    if [[ -f "${LARAVEL_PROJECT_DIR}/artisan" ]]; then
      log "laravel project already exists at ${LARAVEL_PROJECT_DIR}, running composer install"
      composer install --working-dir="$LARAVEL_PROJECT_DIR" --no-interaction --prefer-dist
    else
      log "creating new laravel project at ${LARAVEL_PROJECT_DIR}"
      install -d -m 0755 "$(dirname "$LARAVEL_PROJECT_DIR")"
      composer create-project laravel/laravel "$LARAVEL_PROJECT_DIR" --no-interaction --prefer-dist
    fi
  fi
fi

log "application stacks setup complete"
