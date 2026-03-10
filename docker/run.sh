#! /usr/bin/env bash
set -e

IMAGE_NAME="cmock-dev-arch"
VOLUME_NAME="cmock-dev-workspace"
CONTAINER_WORKDIR="/workspace"

export MSYS_NO_PATHCONV=1

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)"
source "$SCRIPT_DIR/Resources/logging.sh"

if [[ ! -f "$SCRIPT_DIR/.env" ]]; then
	error "No .env file present. Please create it and set GIT_USER_NAME and GIT_USER_EMAIL before proceeding"
	exit 1
fi

SSH_KEYS=()

if [[ -f ${HOME}/.ssh/id_ed25519 ]]; then
	SSH_KEYS+=("-v" "${HOME}/.ssh/id_ed25519:/home/Dev/.ssh/id_ed25519:ro")
	SSH_KEYS+=("-v" "${HOME}/.ssh/id_ed25519.pub:/home/Dev/.ssh/id_ed25519.pub:ro")
fi

if [[ -f ${HOME}/.ssh/id_rsa ]]; then
	SSH_KEYS+=("-v" "${HOME}/.ssh/id_rsa:/home/Dev/.ssh/id_rsa:ro")
	SSH_KEYS+=("-v" "${HOME}/.ssh/id_rsa.pub:/home/Dev/.ssh/id_rsa.pub:ro")
fi

OS_TYPE="$(uname -s)"

DOCKER_RUN_ARGS=(
	-it
	--rm
	-v "${VOLUME_NAME}:${CONTAINER_WORKDIR}"
	-w "${CONTAINER_WORKDIR}"
	${SSH_KEYS[@]}
)

docker run --env-file .env ${DOCKER_RUN_ARGS[@]} "$IMAGE_NAME"
