#/bin/bash
set -eo pipefail

cd $(dirname $0)
source ../env.sh

RELEASE_TAG="$(github_last_release_tag "Comfy-Org/ComfyUI")"

PRESET=preset.$RELEASE_TAG-rocm-7.14.sh
if ! [ -f "$PRESET" ]; then
  echo "Creating preset $PRESET"
  echo "#!/bin/bash

export COMFYUI_ROCM_VERSION='7.14'
export COMFYUI_PYTORCH_VERSION='2.13.0'
export COMFYUI_BRANCH='$RELEASE_TAG'" > "$PRESET"
fi
