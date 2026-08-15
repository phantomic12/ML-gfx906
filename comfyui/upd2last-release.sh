#!/bin/bash
set -euo pipefail

cd "$(dirname "$0")"

RELEASE_TAG="$(curl --fail --silent --show-error --location \
  -H "Accept: application/vnd.github+json" \
  -H "X-GitHub-Api-Version: 2022-11-28" \
  'https://api.github.com/repos/Comfy-Org/ComfyUI/releases?per_page=1' | yq -er '.[0].tag_name')"

if [ -z "$RELEASE_TAG" ] || [ "$RELEASE_TAG" == "null" ]; then
  echo "ERROR: can not resolve last release tag from Comfy-Org/ComfyUI" >&2
  exit 1
fi

PRESET=preset.$RELEASE_TAG-rocm-7.14.sh
if ! [ -f "$PRESET" ]; then
  echo "Creating preset $PRESET"
  echo "#!/bin/bash

export COMFYUI_ROCM_VERSION='7.14'
export COMFYUI_PYTORCH_VERSION='2.13.0'
export COMFYUI_BRANCH='$RELEASE_TAG'" > "$PRESET"
fi
