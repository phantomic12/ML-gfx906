#!/usr/bin/env bash
#
# One-shot migration: pull every .deb from the current homelab S3 apt repo
# (s3.arkprojects.space/apt-gfx906) and upload them as GitHub Release assets.
#
# Usage:
#   ./scripts/migrate-from-s3.sh [RELEASE_TAG]
# Default RELEASE_TAG: 20260802001858 (latest TheRock build set, 145 debs / ~1.4 GB)
#
# Requires: gh (authenticated), curl. Downloads resume via curl -C -.
set -euo pipefail

RELEASE_TAG="${1:-20260802001858}"
S3_BASE="https://s3.arkprojects.space/apt-gfx906/ubuntu"
WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

echo "==> Fetching current Packages index from homelab S3"
curl -fsSL -m 120 "$S3_BASE/dists/noble/main/binary-amd64/Packages" -o "$WORK/Packages"

echo "==> Downloading .deb files (resume-capable)"
mkdir -p "$WORK/debs"
TOTAL=0
while read -r fname fsize; do
  [ -n "$fname" ] || continue
  TOTAL=$((TOTAL + 1))
  base="$(basename "$fname")"
  if [ -f "$WORK/debs/$base" ] && [ "$(stat -c %s "$WORK/debs/$base")" = "$fsize" ]; then
    continue
  fi
  curl -fsSL -m 1800 -C - "$S3_BASE/$fname" -o "$WORK/debs/$base" || {
    echo "FAILED: $fname"; exit 1
  }
done < <(awk '/^Filename: /{f=$2} /^Size: /{print f, $2}' "$WORK/Packages")
echo "    downloaded $TOTAL unique debs: $(du -sh "$WORK/debs" | cut -f1)"

echo "==> Creating release $RELEASE_TAG"
gh release view "$RELEASE_TAG" >/dev/null 2>&1 \
  || gh release create "$RELEASE_TAG" \
       --title "$RELEASE_TAG" \
       --notes "gfx906 package build (migrated from s3.arkprojects.space)" \
       || true

echo "==> Uploading assets (this is the long step)"
gh release upload "$RELEASE_TAG" "$WORK"/debs/*.deb --clobber

echo "==> Done. Run the 'Publish APT repo to GitHub Pages' workflow to regenerate the index."
