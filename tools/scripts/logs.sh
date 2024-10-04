#!/usr/bin/env bash
set -euo pipefail

export NC='\033[0m'
export BL_GREEN='\033[0;92m'
export BL_GRAY='\033[0;90m'
export B_GRAY='\033[1;37m'

# log functions
log(){
  echo -e "${BL_GRAY}[$(date "+%Y-%m-%dT%T%z")]${NC} $*"
}

log_info(){
  # $1 is the module name
  # $2 is the message
  set +u
  log "${BL_GREEN}INFO${NC} ${BL_GRAY}$1${NC} // ${B_GRAY}$2${NC}"
  set -u
}
