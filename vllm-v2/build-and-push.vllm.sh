#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh "vllm-v2" "pytorch"

IMAGE_TAGS=(
  "${VLLM_IMAGE}:${VLLM_PRESET_NAME}-${REPO_GIT_REF}"
  "${VLLM_IMAGE}:${VLLM_PRESET_NAME}"
)

skip_if_image_pushed "${IMAGE_TAGS[0]}" "$VLLM_FORCE_BUILD"

DOCKER_EXTRA_ARGS=()
append_tags_and_annotations_args

DOCKER_EXTRA_ARGS+=(
  --push
  --build-arg "BASE_PYTORCH_IMAGE=${TORCH_IMAGE}:${VLLM_PYTORCH_VERSION}-rocm-${VLLM_ROCM_VERSION}"
  --build-arg "MAX_JOBS=${VLLM_MAX_JOBS}"
  --build-arg "EXTRA_REQUIREMENTS=${VLLM_EXTRA_REQUIREMENTS}"

  --build-arg "VLLM_REPO=${VLLM_REPO}"
  --build-arg "VLLM_BRANCH=${VLLM_BRANCH}"
  --build-arg "VLLM_COMMIT=${VLLM_COMMIT}"
  --build-arg "VLLM_PATCH=${VLLM_PATCH}"

  --build-arg "FA_REPO=${VLLM_FA_REPO}"
  --build-arg "FA_BRANCH=${VLLM_FA_BRANCH}"
  --build-arg "FA_COMMIT=${VLLM_FA_COMMIT}"
  --build-arg "FA_PATCH=${VLLM_FA_PATCH}"

  --build-arg "TRITON_REPO=${VLLM_TRITON_REPO}"
  --build-arg "TRITON_BRANCH=${VLLM_TRITON_BRANCH}"
  --build-arg "TRITON_COMMIT=${VLLM_TRITON_COMMIT}"
  --build-arg "TRITON_PATCH=${VLLM_TRITON_PATCH}"

  --progress=plain
  --target final
  -f ./vllm.Dockerfile
)

docker_build_with_log
