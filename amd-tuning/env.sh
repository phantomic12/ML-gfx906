#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

set_default AMD_TUNING_VERSION "0.0.0"
set_default AMD_TUNING_PUSH "0"
set_default AMD_TUNING_BASE_IMAGE "docker.io/library/ubuntu:24.04"

popd > /dev/null
