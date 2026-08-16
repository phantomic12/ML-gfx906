#/bin/bash

source "$(dirname "${BASH_SOURCE[0]}")/scripts/lib/build-lib.sh"

if [ "$REPO_GIT_REF" == "" ]; then
  REPO_GIT_REF="$(git_get_current_tag || true)"
fi
if [ "$REPO_GIT_REF" == "" ]; then
  REPO_GIT_REF="$(git_get_current_sha || true)"
fi
if [ "$REPO_GIT_REF" == "" ]; then
  env_fail "can not resolve REPO_GIT_REF from git (no tag/commit found). Set REPO_GIT_REF explicitly"
fi

# docker buildx remote connection "graceful_stop" fix
export GRPC_GO_KEEPALIVE_TIME_MS=20000
export GRPC_GO_KEEPALIVE_TIMEOUT_MS=10000

if [ "$1" != "" ]; then
  ENV_ROOT="$(dirname "${BASH_SOURCE[0]}")"
  for PROJ in "$@"; do
    PROJ_ENV="$ENV_ROOT/$PROJ/env.sh"
    if ! [ -f "$PROJ_ENV" ]; then
      env_fail "no env.sh for project \"$PROJ\" ($PROJ_ENV)"
    fi
    source "$PROJ_ENV" || env_fail "failed to source $PROJ_ENV"
  done
fi
