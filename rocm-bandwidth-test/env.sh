#!/bin/bash

pushd "$(dirname "${BASH_SOURCE[0]}")" > /dev/null

set_default RBT_VERSION "develop"
set_default RBT_PUSH "0"

popd > /dev/null
