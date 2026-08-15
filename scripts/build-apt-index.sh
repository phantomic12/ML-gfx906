#!/usr/bin/env bash
#
# Build a FLAT Debian/apt repository from .deb files hosted as GitHub Release
# assets. Flat repos (source line "deb URL ./") make apt fetch Packages,
# Release, InRelease at the repo root — which maps 1:1 onto GitHub's flat
# release assets (no dists/ nesting, no absolute Filename URLs — apt cannot
# fetch absolute Filename URLs; it always joins base URI + Filename).
#
# $SITE_DIR (uploaded as release assets alongside the debs):
#
#   Packages{, .gz, .xz}
#   Release
#   InRelease
#   Release.gpg
#   pubkey.asc
#
# $PAGES_DIR (deployed to GitHub Pages — key and landing page only, never the
# debs: the Pages site is capped at 1 GB and a build set is ~1.4 GB):
#
#   pubkey.asc
#   index.html
#
# Env: DEBS_DIR, RELEASE_TAG, SITE_DIR, PAGES_DIR, KEY_ID
set -euo pipefail

DEBS_DIR="${DEBS_DIR:-debs}"
RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG required}"
SITE_DIR="${SITE_DIR:-site}"
PAGES_DIR="${PAGES_DIR:-pages}"
KEY_ID="${KEY_ID:?KEY_ID required (GPG signing key id)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

command -v apt-ftparchive >/dev/null || { echo "missing apt-ftparchive (apt-utils)"; exit 1; }
command -v gpg >/dev/null || { echo "missing gpg (gnupg)"; exit 1; }
if [ ! -f "$REPO_ROOT/pubkey.asc" ]; then
  # What the documented install instructions fetch: publishing without it gives
  # users a repo they cannot add.
  echo "missing $REPO_ROOT/pubkey.asc"
  exit 1
fi

echo "==> Cleaning $SITE_DIR and $PAGES_DIR"
rm -rf "$SITE_DIR" "$PAGES_DIR"
mkdir -p "$SITE_DIR" "$PAGES_DIR"
# Absolute from here on: the index is generated with $SITE_DIR as cwd, so
# relative paths would resolve inside the site tree itself.
SITE_DIR="$(cd "$SITE_DIR" && pwd)"
PAGES_DIR="$(cd "$PAGES_DIR" && pwd)"

echo "==> Staging debs from $DEBS_DIR"
DEB_COUNT=0
for deb in "$DEBS_DIR"/*.deb; do
  [ -f "$deb" ] || continue
  cp "$deb" "$SITE_DIR/"
  DEB_COUNT=$((DEB_COUNT + 1))
done
if [ "$DEB_COUNT" -eq 0 ]; then
  # An empty index still signs and publishes fine, and makes every package
  # vanish for users whose `apt update` keeps succeeding.
  echo "no .deb files found in $DEBS_DIR — refusing to publish an empty index"
  exit 1
fi
echo "    staged $DEB_COUNT debs ($(du -sh "$SITE_DIR" | cut -f1))"

echo "==> Generating Packages (flat)"
cd "$SITE_DIR"
apt-ftparchive packages . > Packages.tmp
# Flat repo: Filename must be a bare basename relative to the repo root
sed -E "s|^Filename: \.//*|Filename: |" Packages.tmp > Packages
rm -f Packages.tmp
if grep -q '^Filename: .*/' Packages; then
  echo "Filename: entries must be bare basenames in a flat repo:"
  grep '^Filename: .*/' Packages | head
  exit 1
fi
gzip -9 -c Packages > Packages.gz
xz -9 -c Packages > Packages.xz

echo "==> Generating Release"
CONF="$(mktemp)"
RELEASE_TMP="$(mktemp)"
trap 'rm -f "$CONF" "$RELEASE_TMP"' EXIT
cat > "$CONF" <<EOF
APT::FTPArchive::Release::Origin "GitHub Releases gfx906";
APT::FTPArchive::Release::Label "gfx906";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "gfx906";
APT::FTPArchive::Release::Architectures "amd64";
EOF
# Written outside $SITE_DIR: apt-ftparchive hashes the index files it walks, and
# would otherwise checksum the partially written Release file itself.
apt-ftparchive release -c "$CONF" . > "$RELEASE_TMP"
cp "$RELEASE_TMP" Release

echo "==> Signing (key $KEY_ID)"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --clearsign -o InRelease Release
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --detach-sign --armor -o Release.gpg Release

echo "==> Assembling Pages content (pubkey + landing page, no debs)"
cp "$REPO_ROOT/pubkey.asc" "$SITE_DIR/pubkey.asc"
cp "$REPO_ROOT/pubkey.asc" "$PAGES_DIR/pubkey.asc"
if [ -f "$REPO_ROOT/index.html" ]; then
  # Keep the documented sources URI pointing at the release being published.
  sed -E "s|(releases/download)/[^/\"' ]+|\1/$RELEASE_TAG|g" \
    "$REPO_ROOT/index.html" > "$PAGES_DIR/index.html"
fi

echo "==> Done"
find "$SITE_DIR" "$PAGES_DIR" -maxdepth 1 -type f -not -name '*.deb' | sort
