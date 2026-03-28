#!/usr/bin/env bash

set -e

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/logging.sh"

section "Running container initialization.."

if [[ -n "${GIT_USER_NAME:-}" ]]; then
	git config --global user.name "$GIT_USER_NAME"
fi

if [[ -n "${GIT_USER_EMAIL:-}" ]]; then
	git config --global user.email "$GIT_USER_EMAIL"
fi

git config --global credential.helper 'cache --timeout=36000'

section "Git config inside container:"
log "User name: $(git config --global --get user.name || "(user.name not set)")"
log "User email: $(git config --global --get user.email || "(user.email not set)")"

section "Searching for CMock forked repository"

CMOCK_REPO="/workspace/CMock"
CMOCK_REFERENCE="/opt/CMock"

if [[ ! -d "$CMOCK_REPO/.git" ]]; then
	log "CMock repository not found in workspace. Seeding CMock into workspace volume"
	cp -a "$CMOCK_REFERENCE" "$CMOCK_REPO"
	cd $CMOCK_REPO && git remote set-url origin git@github.com:$GIT_USER_NAME/CMock.git
	success "CMock seeded successfully"
else
	success "CMock repository found in workspace"
fi

echo;
