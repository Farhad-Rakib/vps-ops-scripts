#!/usr/bin/env bash

set -euo pipefail

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*"
}

warn() {
  printf '[%s] WARN: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
}

die() {
  printf '[%s] ERROR: %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" >&2
  exit 1
}

is_true() {
  [[ "${1:-0}" == "1" ]]
}

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    die "run this script as root or with sudo"
  fi
}

source_config() {
  local config_path="${1:-}"
  [[ -n "$config_path" ]] || die "missing config path"
  [[ -f "$config_path" ]] || die "config file not found: $config_path"
  # shellcheck disable=SC1090
  source "$config_path"
}

detect_os() {
  if [[ -r /etc/os-release ]]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    printf '%s:%s\n' "${ID:-unknown}" "${VERSION_CODENAME:-${UBUNTU_CODENAME:-unknown}}"
  else
    printf 'unknown:unknown\n'
  fi
}

ensure_apt() {
  command -v apt-get >/dev/null 2>&1 || die "this script currently supports apt-based systems only"
}

apt_install() {
  DEBIAN_FRONTEND=noninteractive apt-get install -y "$@"
}

apt_update() {
  DEBIAN_FRONTEND=noninteractive apt-get update
}
