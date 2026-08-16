#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

# rocm version
set_default TORCH_ROCM_VERSION "7.14"
# torch git checkpoint
set_default TORCH_VERSION "v2.13.0"
# destination image
set_default TORCH_IMAGE "docker.io/mixa3607/pytorch-gfx906"
# push result
set_default TORCH_PUSH "1"
# packages source
set_default TORCH_PACKAGES_SOURCE "fetch"

popd
