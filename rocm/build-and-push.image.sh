#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh "rocm"

IMAGE_TAGS=(
  "$ROCM_IMAGE:${ROCM_VERSION}-complete-${REPO_GIT_REF}"
  "$ROCM_IMAGE:${ROCM_VERSION}-complete"
)

init_image_annotations "ROCm gfx906" "rocm" "${ROCM_BASE_IMAGE}"

echo "Start building ROCm image..."
echo "ROCM_VERSION: ${ROCM_VERSION}"
echo "ROCM_BUILD:   ${ROCM_BUILD}"

DOCKER_EXTRA_ARGS=()
append_tags_and_annotations_args

skip_if_image_pushed "${IMAGE_TAGS[0]}" "$ROCM_FORCE_BUILD"

DOCKER_EXTRA_ARGS+=(
  --build-arg "ROCM_BASE_IMAGE=${ROCM_BASE_IMAGE}"
  --build-arg "ROCM_BUILD=${ROCM_BUILD}"
  --progress plain
  --target final 
  --file ./build-image.Dockerfile
  --pull
)

if [ "$ROCM_PUSH" == "1" ]; then
  DOCKER_EXTRA_ARGS+=(
    --push
  )
fi

echo "Install ROCm packages to image"
docker_build_with_log
