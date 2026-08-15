#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh "llama.cpp" "rocm"

LLAMA_BASE_IMAGE="${ROCM_IMAGE}:${LLAMA_ROCM_VERSION}-complete"
if [ "$LLAMA_IS_RELEASE" == "1" ]; then
  IMAGE_TAGS=(
    "${LLAMA_IMAGE}:${LLAMA_PRESET_NAME}-${REPO_GIT_REF}"
    "${LLAMA_IMAGE}:${LLAMA_PRESET_NAME}"
  )
else
  IMAGE_TAGS=(
    "${LLAMA_IMAGE}:${LLAMA_PRESET_NAME}-${REPO_GIT_REF}-pre"
  )
fi

init_image_annotations "Llama.cpp gfx906" "llama.cpp" "${LLAMA_BASE_IMAGE}"

echo "Start building llama.cpp image..."
echo "LLAMA_REPO:       ${LLAMA_REPO}"
echo "LLAMA_BRANCH:     ${LLAMA_BRANCH}"
echo "LLAMA_COMMIT:     ${LLAMA_COMMIT}"
echo "LLAMA_CODE_PATH:  ${LLAMA_CODE_PATH}"
echo "LLAMA_PATCH:      ${LLAMA_PATCH}"
echo "ROCM_ARCH:        ${ROCM_ARCH}"
echo "ROCM_VERSION:     ${LLAMA_ROCM_VERSION}"
echo "CMAKE_HIP_FLAGS:  ${LLAMA_CMAKE_HIP_FLAGS}"
echo "CCACHE_MAXSIZE:   ${LLAMA_CCACHE_MAXSIZE}"
echo "IS_RELEASE:       ${LLAMA_IS_RELEASE}"

DOCKER_EXTRA_ARGS=()
append_tags_and_annotations_args
skip_if_image_pushed "${IMAGE_TAGS[0]}" "$LLAMA_FORCE_BUILD"

DOCKER_EXTRA_ARGS+=(
  --build-arg ROCM_IMAGE="${LLAMA_BASE_IMAGE}"
  --build-arg ROCM_ARCH="${ROCM_ARCH}"
  --build-arg LLAMACPP_REPO="${LLAMA_REPO}"
  --build-arg LLAMACPP_BRANCH="${LLAMA_BRANCH}"
  --build-arg LLAMACPP_COMMIT="${LLAMA_COMMIT}"
  --build-arg LLAMACPP_CODE_PATH="${LLAMA_CODE_PATH}"
  --build-arg LLAMACPP_PATCH="${LLAMA_PATCH}"
  --build-arg CMAKE_HIP_FLAGS="${LLAMA_CMAKE_HIP_FLAGS}"
  --build-arg CCACHE_MAXSIZE="${LLAMA_CCACHE_MAXSIZE}"
  --progress plain
  --target final 
  --file ./build-image.Dockerfile
  --pull
)

if [ "$LLAMA_PUSH" == "1" ]; then
  DOCKER_EXTRA_ARGS+=(
    --push
  )
fi

echo "Build llama.cpp"
docker_build_with_log
