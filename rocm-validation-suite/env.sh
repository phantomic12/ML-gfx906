#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

# ROCmValidationSuite git tag/branch to build
set_default RVS_VERSION "main"
# push result
set_default RVS_PUSH "0"

popd
