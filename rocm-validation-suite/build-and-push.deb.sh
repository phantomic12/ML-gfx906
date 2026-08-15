#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh "rocm-validation-suite" "rocm"

RVS_VERSION_SUFFIX="${ROCM_VERSION}+${ROCM_ARCH}+${REPO_GIT_REF}"
RVS_BASE_IMAGE="${ROCM_IMAGE}:${ROCM_VERSION}-complete"
RVS_PACKAGES_DIR="$PWD/output/rocm${ROCM_VERSION}/rvs-${RVS_VERSION}-${RVS_VERSION_SUFFIX}"

echo "Start building ROCm Validation Suite deb package..."
echo "RVS VERSION:        ${RVS_VERSION}"
echo "RVS VERSION SUFFIX: ${RVS_VERSION_SUFFIX}"
echo "RVS PACKAGES DIR:   ${RVS_PACKAGES_DIR}"
echo "ROCM IMAGE:         ${RVS_BASE_IMAGE}"
echo "ROCM ARCH:          ${ROCM_ARCH}"
echo "ROCM VERSION:       ${ROCM_VERSION}"
echo "PUSH:               ${RVS_PUSH}"

skip_if_dir_exists "$RVS_PACKAGES_DIR" "$RVS_FORCE_BUILD"

DOCKER_EXTRA_ARGS=(
  --build-arg "BASE_ROCM_IMAGE=${RVS_BASE_IMAGE}"
  --build-arg "VERSION_SUFFIX=${RVS_VERSION_SUFFIX}"
  --build-arg "RVS_BRANCH=${RVS_VERSION}"
  --progress plain
  --pull
  --target final 
  --file ./build-deb.Dockerfile
  --output "type=local,dest=$RVS_PACKAGES_DIR"
)

docker_build_with_log

# Push packages
if [ "$RVS_PUSH" == "1" ]; then
  scp_debs "$RVS_PACKAGES_DIR" "rocm-validation-suite"
fi
