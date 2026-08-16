#!/usr/bin/env bash
#
# One-shot migration: pull every .deb from the current homelab S3 apt repo
# (s3.arkprojects.space/apt-gfx906) and upload them as GitHub Release assets.
#
# Usage:
#   ./scripts/migrate-from-s3.sh [RELEASE_TAG]
# Default RELEASE_TAG: 20260802001858 (latest TheRock build set, 145 debs / ~1.4 GB)
#
# Downloads are resumable (curl -C -) and verified against the SHA256 recorded
# in the upstream Packages index, so re-running only fetches what is missing or
# corrupt. Work dir: $MIGRATE_DIR (default <repo>/migrate-debs), kept on exit.
#
# Requires: gh (authenticated), curl, sha256sum
set -euo pipefail

RELEASE_TAG="${1:-20260802001858}"
S3_BASE="https://s3.arkprojects.space/apt-gfx906/ubuntu"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
WORK="${MIGRATE_DIR:-$REPO_ROOT/migrate-debs}"
mkdir -p "$WORK/debs"

echo "==> Fetching current Packages index from homelab S3"
curl -fsSL -m 120 "$S3_BASE/dists/noble/main/binary-amd64/Packages" -o "$WORK/Packages"

# One "<path> <size> <sha256>" line per stanza. Fields are emitted at the end of
# each stanza so their order inside it does not matter, and stanzas missing a
# field are reported instead of silently pairing values from their neighbours.
awk '
  function flush() {
    if (f != "") {
      if (s == "" || h == "") {
        print "incomplete stanza for " f > "/dev/stderr"
        f = ""   # END re-runs flush() after exit
        exit 1
      }
      print f, s, h
    }
    f = ""; s = ""; h = ""
  }
  /^Filename: /  { f = $2 }
  /^Size: /      { s = $2 }
  /^SHA256: /    { h = $2 }
  /^$/           { flush() }
  END            { flush() }
' "$WORK/Packages" > "$WORK/manifest"

echo "==> Downloading .deb files ($(wc -l < "$WORK/manifest") in index)"
FETCHED=0
KEPT=0
declare -A CLAIMED_BY=()
while read -r fname fsize fsha; do
  base="$(basename "$fname")"
  dest="$WORK/debs/$base"
  # Distinct pool paths sharing a basename would overwrite each other here.
  if [ -n "${CLAIMED_BY[$base]:-}" ]; then
    echo "FILENAME COLLISION: $fname and ${CLAIMED_BY[$base]} share basename $base"
    exit 1
  fi
  CLAIMED_BY[$base]="$fname"

  if [ -f "$dest" ] && [ "$(stat -c %s "$dest")" = "$fsize" ] \
     && [ "$(sha256sum "$dest" | cut -d' ' -f1)" = "$fsha" ]; then
    KEPT=$((KEPT + 1))
    continue
  fi

  # Resume first; a stale/mismatched file can make the server reject the range,
  # so fall back to a clean re-download before giving up.
  curl -fsSL -m 1800 -C - "$S3_BASE/$fname" -o "$dest" \
    || { rm -f "$dest"; curl -fsSL -m 1800 "$S3_BASE/$fname" -o "$dest"; } \
    || { echo "FAILED: $fname"; exit 1; }

  if [ "$(sha256sum "$dest" | cut -d' ' -f1)" != "$fsha" ]; then
    echo "SHA256 MISMATCH: $fname"
    exit 1
  fi
  FETCHED=$((FETCHED + 1))
done < "$WORK/manifest"
echo "    fetched $FETCHED, already present $KEPT ($(du -sh "$WORK/debs" | cut -f1))"

echo "==> Creating release $RELEASE_TAG"
if ! gh release view "$RELEASE_TAG" >/dev/null 2>&1; then
  gh release create "$RELEASE_TAG" \
    --title "$RELEASE_TAG" \
    --notes "gfx906 package build (migrated from s3.arkprojects.space)"
fi

echo "==> Uploading assets (this is the long step)"
# Per-file with retries: a single flaky asset must not fail the whole batch,
# and --clobber makes each upload idempotent across re-runs.
for deb in "$WORK"/debs/*.deb; do
  for attempt in 1 2 3; do
    if gh release upload "$RELEASE_TAG" "$deb" --clobber; then
      break
    fi
    if [ "$attempt" = 3 ]; then
      echo "FAILED to upload $deb after 3 attempts"
      exit 1
    fi
    echo "    retrying $(basename "$deb") ($attempt/3)"
    sleep $((attempt * 10))
  done
done

echo "==> Done. Run the 'Publish APT repo to GitHub Pages' workflow to regenerate the index."
