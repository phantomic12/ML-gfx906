#/bin/bash

source $(dirname ${BASH_SOURCE[0]})/scripts/lib/build-lib.sh

if [ "$REPO_GIT_REF" == "" ]; then
  REPO_GIT_REF="$(git_get_current_tag)"
fi
if [ "$REPO_GIT_REF" == "" ]; then
  REPO_GIT_REF="$(git_get_current_sha)"
fi

# docker buildx remote connection "graceful_stop" fix
export GRPC_GO_KEEPALIVE_TIME_MS=20000
export GRPC_GO_KEEPALIVE_TIMEOUT_MS=10000

if [ "$1" != "" ]; then
  for PROJ in "$@"; do
    source $(dirname ${BASH_SOURCE[0]})/${PROJ}/env.sh
  done
fi
