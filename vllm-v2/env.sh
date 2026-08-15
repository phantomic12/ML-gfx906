#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

set_default VLLM_IMAGE "docker.io/mixa3607/vllm-gfx906"
set_default VLLM_PRESET_NAME "default"
# vllm git checkpoint
set_default VLLM_REPO "https://github.com/ai-infos/vllm-gfx906-mobydick.git"
set_default VLLM_BRANCH "main"
set_default VLLM_PATCH "empty.patch"
# triton git checkpoint
set_default VLLM_TRITON_REPO "https://github.com/ai-infos/triton-gfx906.git"
set_default VLLM_TRITON_BRANCH "v3.5.1+gfx906"
set_default VLLM_TRITON_PATCH "empty.patch"
# fa git checkpoint
set_default VLLM_FA_REPO "https://github.com/ai-infos/flash-attention-gfx906.git"
set_default VLLM_FA_BRANCH "gfx906/v2.8.3.x"
set_default VLLM_FA_PATCH "empty.patch"
# rocm version
set_default VLLM_ROCM_VERSION "6.3.3"
# torch git checkpoint
set_default VLLM_PYTORCH_VERSION "v2.10.0"

popd
