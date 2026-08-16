#/bin/bash
# Shared helpers for the per subproject build-and-push.* scripts.
# Sourced automatically by the root env.sh.

# Abort the calling build script with a message.
function env_fail {
  echo "ERROR: $*" >&2
  exit 1
}

# Set a variable only when it is unset or empty.
# Usage: set_default VAR_NAME "value"
function set_default {
  local name="$1"
  if [ "${!name}" == "" ]; then
    printf -v "$name" '%s' "$2"
  fi
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

# Latest release tag of a github repo. Aborts when it can not be resolved.
# Usage: github_last_release_tag <owner/repo>
function github_last_release_tag {
  local tag
  tag="$(curl --fail --silent --show-error --location \
    -H "Accept: application/vnd.github+json" \
    -H "X-GitHub-Api-Version: 2022-11-28" \
    "https://api.github.com/repos/$1/releases?per_page=1" | yq -er '.[0].tag_name')" || tag=""
  if [ -z "$tag" ] || [ "$tag" == "null" ]; then
    env_fail "can not resolve last release tag from $1"
  fi
  echo "$tag"
}

# Fill IMAGE_ANNOTATIONS with the common OCI annotations.
# Usage: init_image_annotations <image title> <subproject dir> <base image>
function init_image_annotations {
  declare -g -A IMAGE_ANNOTATIONS=()
  IMAGE_ANNOTATIONS["org.opencontainers.image.created"]="$(date --rfc-3339=seconds)"
  IMAGE_ANNOTATIONS["org.opencontainers.image.authors"]="mixa3607"
  IMAGE_ANNOTATIONS["org.opencontainers.image.source"]="https://github.com/mixa3607/ML-gfx906/tree/${REPO_GIT_REF}/$2"
  IMAGE_ANNOTATIONS["org.opencontainers.image.version"]="${REPO_GIT_REF}"
  IMAGE_ANNOTATIONS["org.opencontainers.image.title"]="$1"
  IMAGE_ANNOTATIONS["org.opencontainers.image.base.name"]="$3"
}

# Print IMAGE_TAGS/IMAGE_ANNOTATIONS and append them to DOCKER_EXTRA_ARGS.
function append_tags_and_annotations_args {
  local tag key
  for tag in "${IMAGE_TAGS[@]}"; do
    echo "TAG:          ${tag}"
    DOCKER_EXTRA_ARGS+=("--tag" "$tag")
  done
  for key in "${!IMAGE_ANNOTATIONS[@]}"; do
    echo "ANNOTATION:   ${key}: ${IMAGE_ANNOTATIONS[$key]}"
    DOCKER_EXTRA_ARGS+=("--annotation" "${key}=${IMAGE_ANNOTATIONS[$key]}")
  done
}

# Exit the calling script when the artefact already exists and force build is off.
# Usage: skip_if_built <reason> <force build flag>
function skip_if_built {
  echo -n "$1 "
  if [ "$2" == "1" ]; then
    echo "Force build..."
  else
    echo "Skip."
    exit 0
  fi
}

# Usage: skip_if_image_pushed <image tag> <force build flag>
function skip_if_image_pushed {
  if docker_image_pushed_or_fail "$1"; then
    skip_if_built "$1 already in registry." "$2"
  fi
}

# Usage: skip_if_dir_exists <packages dir> <force build flag>
function skip_if_dir_exists {
  if [ -d "$1" ]; then
    skip_if_built "Directory $1 exist." "$2"
  fi
}

# Run docker buildx with DOCKER_EXTRA_ARGS and tee the output to ./logs.
# Usage: docker_build_with_log [build context dir]
function docker_build_with_log {
  mkdir -p ./logs
  docker buildx build "${DOCKER_EXTRA_ARGS[@]}" "${1:-./build-context}" 2>&1 \
    | tee "./logs/build_$(date +%Y%m%d%H%M%S).log"
}

# Copy built deb packages to the packages host. Aborts when nothing was built.
# Usage: scp_debs <packages dir> <packages host subdir>
function scp_debs {
  local debs
  mapfile -t debs < <(find "$1" -maxdepth 1 -mindepth 1 -name "*.deb")
  if [ ${#debs[@]} -eq 0 ]; then
    env_fail "no .deb files in $1 to push"
  fi
  scp "${debs[@]}" "k3s@kube-worker6.arkprojects.lan:/home/k3s/rocm-dev-packages/$2"
}
