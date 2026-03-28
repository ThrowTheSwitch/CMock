#!/usr/bin/env bash

[[ -n "${__LOGGING_SH_LOADED:-}" ]] && return
__LOGGING_SH_LOADED=1

set -o pipefail

if [[ -t 1 ]]; then
	RED='\033[0;31m'
	GREEN='\033[0;92m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;34m'
	MAGENTA='\033[0;35m'
	LIGHT_RED='\033[0;91m'
	CYAN='\033[0;36m'
	BOLD='\033[1m'
	DIM='\033[2m'
	RESET='\033[0m'
	LIGHT_CYAN='\033[0;96m'
	LIGHT_YELLOW='\033[0;93m'
else
	RED=''
	GREEN=''
	YELLOW=''
	BLUE=''
	MAGENTA=''
	LIGHT_RED=''
	CYAN=''
	BOLD=''
	DIM=''
	RESET=''
	LIGHT_CYAN=''
	LIGHT_YELL0W=''
fi

section() { echo -e "${BOLD}${LIGHT_RED}  ==> ${RESET}$*"; }
log() { echo -e "${LIGHT_CYAN}  [\u2139]${RESET} $*"; }
success() { echo -e "${LIGHT_CYAN}  [\u2714]${RESET} $*\n"; }
warn() { echo -e "${YELLOW}  [\u26A0]${RESET} $*"; }
error() { echo -e "${RED}  [\u2716]${RESET} $*" >&2; }

run() {
	log "$*"
	"$0"
}

if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
	trap 'error "Command failed at line ${BASH_LINENO[0]}"' ERR
fi
