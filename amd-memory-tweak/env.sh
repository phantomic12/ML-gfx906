#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

set_default AMT_VERSION "0.0.0"
set_default AMT_PUSH "0"
set_default AMT_BASE_IMAGE "docker.io/library/ubuntu:24.04"

popd > /dev/null
