#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"
source ../scripts/lib/build-lib.sh

RELEASE_TAG="$(github_last_release_tag "ggml-org/llama.cpp")"

PRESET=preset.$RELEASE_TAG-rocm-7.14.sh
if ! [ -f "$PRESET" ]; then
  echo "Creating preset $PRESET"
  echo "#!/bin/bash

export LLAMA_ROCM_VERSION='7.14'
export LLAMA_BRANCH='$RELEASE_TAG'
export LLAMA_PRESET_NAME='$RELEASE_TAG-rocm-7.14'
" > "$PRESET"
fi
