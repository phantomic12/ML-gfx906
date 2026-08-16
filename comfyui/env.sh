#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

set_default COMFYUI_IMAGE "docker.io/mixa3607/comfyui-gfx906"
set_default COMFYUI_TORCH_IMAGE "docker.io/mixa3607/pytorch-gfx906"
set_default COMFYUI_ROCM_VERSION "6.3.3"
set_default COMFYUI_PYTORCH_VERSION "2.7.1"

set_default COMFYUI_REPO "https://github.com/Comfy-Org/ComfyUI.git"
set_default COMFYUI_BRANCH "master"
set_default COMFYUI_COMMIT ""

# push image
set_default COMFYUI_PUSH "1"

popd
