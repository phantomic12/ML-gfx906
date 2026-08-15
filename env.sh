#/bin/bash

# Abort the calling build script with a message.
function env_fail {
  echo "ERROR: $*" >&2
  exit 1
}

# 0 - image is in registry
# 1 - image is not in registry
# 2 - registry could not be queried (auth, network, no docker, ...)
function docker_image_pushed {
  local output rc=0
  output="$(docker buildx imagetools inspect "$1" 2>&1)" || rc=$?
  if [ $rc -eq 0 ]; then
    return 0
  fi
  if grep -qiE 'not found|manifest unknown|manifest_unknown|name_unknown|no such manifest|does not exist' <<< "$output"; then
    return 1
  fi
  echo "ERROR: failed to inspect $1:" >&2
  echo "$output" >&2
  return 2
}

# Same as docker_image_pushed, but a registry error aborts instead of being
# reported as "not in registry" (which would silently rebuild and overwrite).
function docker_image_pushed_or_fail {
  local rc=0
  docker_image_pushed "$1" || rc=$?
  case $rc in
    0) return 0 ;;
    1) return 1 ;;
    *) env_fail "can not determine whether $1 is already in the registry" ;;
  esac
}

function git_get_current_tag {
  local out
  out="$(git -C "${1:-.}" tag --points-at HEAD)" || return 1
  echo "$out" | sed 's|+||g'
}

function git_get_origin {
  git -C "${1:-.}" config --get remote.origin.url
}

function git_get_current_sha {
  git -C "${1:-.}" rev-parse --short HEAD
}

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
