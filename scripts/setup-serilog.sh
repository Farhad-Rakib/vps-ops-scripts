#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck disable=SC1091
source "$SCRIPT_DIR/common.sh"

CONFIG_PATH="${1:-${SCRIPT_DIR}/../config.sh}"
source_config "$CONFIG_PATH"

is_true "${ENABLE_SERILOG:-0}" || die "ENABLE_SERILOG must be set to 1"

[[ -n "${DOTNET_PROJECT_DIR:-}" ]] || die "DOTNET_PROJECT_DIR is required"
command -v dotnet >/dev/null 2>&1 || die "dotnet CLI was not found"

project_path="${DOTNET_PROJECT_DIR}"
if [[ -d "$project_path" ]]; then
  project_file="$(find "$project_path" -maxdepth 1 -name '*.csproj' | head -n 1)"
else
  project_file="$project_path"
fi

[[ -f "$project_file" ]] || die "no .csproj found at ${DOTNET_PROJECT_DIR}"

packages=()
if declare -p SERILOG_PACKAGES >/dev/null 2>&1; then
  packages=("${SERILOG_PACKAGES[@]}")
else
  packages=(Serilog.AspNetCore Serilog.Settings.Configuration Serilog.Sinks.Console)
fi

for package_name in "${packages[@]}"; do
  log "adding ${package_name}"
  dotnet add "$project_file" package "$package_name"
done

log "serilog packages added"
