#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

# value from tag https://github.com/ROCm/TheRock/tags therock-<VERSION>
set_default ROCM_VERSION "7.14"
set_default ROCM_ARCH "gfx906"
set_default ROCM_BUILD "$ROCM_VERSION.0-$ROCM_ARCH+$REPO_GIT_REF"
# base image
set_default ROCM_BASE_IMAGE "docker.io/library/ubuntu:24.04"
# destination image
set_default ROCM_IMAGE "docker.io/mixa3607/rocm-gfx906"
# push image
set_default ROCM_PUSH "1"

popd
