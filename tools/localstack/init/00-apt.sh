#!/usr/bin/env bash
set -euo pipefail

source "/tmp/scripts/logs.sh"

main() {
  apt_update
  apt_install
}

apt_update() {
  log_info "apt" "update"
  apt-get update
}

apt_install() {
  log_info "apt" "install missing packages"
  apt-get install -y --no-install-recommends \
    jq
}

main
