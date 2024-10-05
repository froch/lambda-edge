#!/usr/bin/env bash
set -euo pipefail

export NC='\033[0m'
export BL_GREEN='\033[0;92m'
export BL_GRAY='\033[0;90m'
export BL_RED='\033[0;91m'
export B_GRAY='\033[1;37m'

# log functions
log(){
  echo -e "${BL_GRAY}[$(date "+%Y-%m-%dT%T%z")]${NC} $*"
}

log_info(){
  local mod=$1
  local msg=$2
  log "${BL_GREEN}INFO${NC} ${BL_GRAY}$mod${NC} // ${B_GRAY}$msg${NC}"
}

log_error(){
  local mod=$1
  local msg=$2
  log "${BL_RED}ERROR${NC} ${BL_GRAY}$mod${NC} // ${B_GRAY}$msg${NC}"
}
