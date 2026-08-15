#!/bin/bash
set -eo pipefail

if [ -z "${ROCM_BUILD:-}" ]; then
  echo "ERROR: ROCM_BUILD is not set" >&2
  exit 1
fi

echo "Searching rocm $ROCM_BUILD packages"
MAJOR_MINOR=$(grep -oE '^[0-9]+\.[0-9]+' <<< "$ROCM_BUILD") || {
  echo "ERROR: no <major>.<minor> version in ROCM_BUILD=$ROCM_BUILD" >&2
  exit 1
}
GPU_TARGET=$(grep -oE 'gfx[0-9]+' <<< "$ROCM_BUILD") || {
  echo "ERROR: no gfx target in ROCM_BUILD=$ROCM_BUILD" >&2
  exit 1
}
ROCM_PACKAGES=(
  amdrocm${MAJOR_MINOR}=${ROCM_BUILD}
  amdrocm-core-sdk${MAJOR_MINOR}=${ROCM_BUILD} 
  amdrocm${MAJOR_MINOR}-${GPU_TARGET}=${ROCM_BUILD} 
  amdrocm-core-sdk${MAJOR_MINOR}-${GPU_TARGET}=${ROCM_BUILD} 
)
echo "Rocm packages to install: ${ROCM_PACKAGES[@]}" 
apt-get install --no-install-recommends -y "${ROCM_PACKAGES[@]}"

echo "Add ROCm to libs"
tee /etc/ld.so.conf.d/rocm.conf <<EOF
# ROCm gfx906
$ROCM_PATH/lib
EOF
ldconfig
