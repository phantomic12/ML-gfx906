#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"
source ../env.sh "amd-memory-tweak"

AMT_VERSION_SUFFIX="gfx906+${REPO_GIT_REF}"
AMT_PACKAGES_DIR="$PWD/output/amt-${AMT_VERSION}-${AMT_VERSION_SUFFIX}"

echo "Start building AMD Memory Tweak deb package..."
echo "AMT VERSION:        ${AMT_VERSION}"
echo "AMT VERSION SUFFIX: ${AMT_VERSION_SUFFIX}"
echo "AMT PACKAGES DIR:   ${AMT_PACKAGES_DIR}"
echo "BASE IMAGE:         ${AMT_BASE_IMAGE}"
echo "PUSH:               ${AMT_PUSH}"

skip_if_dir_exists "$AMT_PACKAGES_DIR" "${AMT_FORCE_BUILD:-0}"

DOCKER_EXTRA_ARGS=(
  --build-arg "BASE_UBUNTU_IMAGE=${AMT_BASE_IMAGE}"
  --build-arg "AMT_VERSION=${AMT_VERSION}"
  --build-arg "VERSION_SUFFIX=${AMT_VERSION_SUFFIX}"
  --progress plain
  --pull
  --target final
  --file ./build-deb.Dockerfile
  --output "type=local,dest=$AMT_PACKAGES_DIR"
)

docker_build_with_log

if [ "$AMT_PUSH" = "1" ]; then
  scp_debs "$AMT_PACKAGES_DIR" "amd-memory-tweak"
fi
