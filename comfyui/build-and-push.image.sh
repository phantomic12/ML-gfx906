#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh "comfyui" "pytorch"

COMFYUI_BASE_IMAGE="${COMFYUI_TORCH_IMAGE}:v${COMFYUI_PYTORCH_VERSION}-rocm-${COMFYUI_ROCM_VERSION}"
IMAGE_TAGS=(
  "$COMFYUI_IMAGE:${COMFYUI_BRANCH}-torch-${COMFYUI_PYTORCH_VERSION}-rocm-${COMFYUI_ROCM_VERSION}-${REPO_GIT_REF}"
  "$COMFYUI_IMAGE:${COMFYUI_BRANCH}-torch-${COMFYUI_PYTORCH_VERSION}-rocm-${COMFYUI_ROCM_VERSION}"
  "$COMFYUI_IMAGE:${COMFYUI_BRANCH}-rocm-${COMFYUI_ROCM_VERSION}-${REPO_GIT_REF}"
  "$COMFYUI_IMAGE:${COMFYUI_BRANCH}-rocm-${COMFYUI_ROCM_VERSION}"
  "$COMFYUI_IMAGE:latest-rocm-${COMFYUI_ROCM_VERSION}"
)

init_image_annotations "ComfyUI gfx906" "comfyui" "${ROCM_BASE_IMAGE}"

echo "Start building ComfyUI image..."
echo "REPO:          ${COMFYUI_REPO}"
echo "VERSION:       ${COMFYUI_BRANCH}"
echo "COMMIT:        ${COMFYUI_COMMIT}"
echo "ROCM_VERSION:  ${COMFYUI_ROCM_VERSION}"
echo "TORCH_VERSION: ${COMFYUI_PYTORCH_VERSION}"

DOCKER_EXTRA_ARGS=()
append_tags_and_annotations_args

skip_if_image_pushed "${IMAGE_TAGS[0]}" "$COMFYUI_FORCE_BUILD"

DOCKER_EXTRA_ARGS+=(
  --build-arg BASE_PYTORCH_IMAGE="${COMFYUI_BASE_IMAGE}"
  --build-arg COMFY_REPO="${COMFYUI_REPO}"
  --build-arg COMFY_BRANCH="${COMFYUI_BRANCH}"
  --build-arg COMFY_COMMIT="${COMFYUI_COMMIT}"
  --progress plain
  --target final 
  --file ./build-image.Dockerfile
  --pull
)

if [ "$COMFYUI_PUSH" == "1" ]; then
  DOCKER_EXTRA_ARGS+=(
    --push
  )
fi

echo "Install ComfyUI to image"
docker_build_with_log
