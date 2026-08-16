#!/bin/bash
set -eo pipefail

cd "$(dirname "$0")"
source ../env.sh "amd-tuning"

AMD_TUNING_VERSION_SUFFIX="gfx906+${REPO_GIT_REF}"
AMD_TUNING_PACKAGES_DIR="$PWD/output/amd-tuning-${AMD_TUNING_VERSION}-${AMD_TUNING_VERSION_SUFFIX}"

echo "Start building AMD tuning deb package..."
echo "AMD TUNING VERSION:        ${AMD_TUNING_VERSION}"
echo "AMD TUNING VERSION SUFFIX: ${AMD_TUNING_VERSION_SUFFIX}"
echo "AMD TUNING PACKAGES DIR:   ${AMD_TUNING_PACKAGES_DIR}"
echo "BASE IMAGE:                ${AMD_TUNING_BASE_IMAGE}"
echo "PUSH:                      ${AMD_TUNING_PUSH}"

skip_if_dir_exists "$AMD_TUNING_PACKAGES_DIR" "${AMD_TUNING_FORCE_BUILD:-0}"

DOCKER_EXTRA_ARGS=(
  --build-arg "BASE_UBUNTU_IMAGE=${AMD_TUNING_BASE_IMAGE}"
  --build-arg "AMD_TUNING_VERSION=${AMD_TUNING_VERSION}"
  --build-arg "VERSION_SUFFIX=${AMD_TUNING_VERSION_SUFFIX}"
  --progress plain
  --pull
  --target final
  --file ./build-deb.Dockerfile
  --output "type=local,dest=$AMD_TUNING_PACKAGES_DIR"
)

docker_build_with_log

if [ "$AMD_TUNING_PUSH" = "1" ]; then
  scp_debs "$AMD_TUNING_PACKAGES_DIR" "amd-tuning"
fi
