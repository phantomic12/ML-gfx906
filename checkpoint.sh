#/bin/bash
set -eo pipefail

cd "$(dirname "$0")"
source ./env.sh

if ! [ -z "$(git status --porcelain)" ]; then
  echo "Workdir is dirty!"
  if [ "${CHECKPOINT_ALLOW_DIRTY:-0}" != "1" ]; then
    echo "Commit/stash changes or set CHECKPOINT_ALLOW_DIRTY=1 to tag anyway." >&2
    exit 10
  fi
fi

TAG_NAME=$(git_get_current_tag)
if [ "$TAG_NAME" == "" ]; then
  TAG_NAME="$(date +%Y%m%d%H%M%S)"
  git tag -a "$TAG_NAME" -m "none"
  echo -e "New tag $TAG_NAME"
else
  echo "Commit already tagged with $TAG_NAME"
fi
