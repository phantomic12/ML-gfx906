#/bin/bash

pushd $(dirname ${BASH_SOURCE[0]})

# TransferBench git tag/branch to build
set_default TB_VERSION "main"
# push result
set_default TB_PUSH "0"

popd
