#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

set_default LLAMA_IMAGE "docker.io/mixa3607/llama.cpp-gfx906"
# rocm ver
set_default LLAMA_ROCM_VERSION "7.14"

set_default LLAMA_REPO "https://github.com/ggml-org/llama.cpp.git"
set_default LLAMA_BRANCH "master"
set_default LLAMA_COMMIT ""
set_default LLAMA_CMAKE_HIP_FLAGS ""
set_default LLAMA_CCACHE_MAXSIZE "2G"
set_default LLAMA_IS_RELEASE "0"
set_default LLAMA_PATCH "empty.patch"

# push image
set_default LLAMA_PUSH "1"

popd
