#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

set_default VLLM_IMAGE "docker.io/mixa3607/vllm-gfx906"
set_default VLLM_PRESET_NAME "default"
# vllm git checkpoint
set_default VLLM_REPO "https://github.com/nlzy/vllm-gfx906.git"
set_default VLLM_BRANCH "v0.10.2"
set_default VLLM_PATCH "empty.patch"
# triton git checkpoint
set_default VLLM_TRITON_REPO "https://github.com/nlzy/triton-gfx906.git"
set_default VLLM_TRITON_BRANCH "v3.4.x"
set_default VLLM_TRITON_PATCH "empty.patch"
# rocm version
set_default VLLM_ROCM_VERSION "6.4.4"
# torch git checkpoint
set_default VLLM_PYTORCH_VERSION "v2.7.1"

popd
