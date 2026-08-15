#!/usr/bin/env bash
#
# Build a FLAT Debian/apt repository from .deb files hosted as GitHub Release
# assets. Flat repos (source line "deb URL ./") make apt fetch Packages,
# Release, InRelease at the repo root — which maps 1:1 onto GitHub's flat
# release assets (no dists/ nesting, no absolute Filename URLs — apt cannot
# fetch absolute Filename URLs; it always joins base URI + Filename).
#
# Output (all flat, uploaded as release assets alongside the debs):
#
#   Packages{, .gz, .xz}
#   Release
#   InRelease
#   Release.gpg
#   pubkey.asc
#
# Env: DEBS_DIR, RELEASE_TAG, SITE_DIR, KEY_ID
set -euo pipefail

DEBS_DIR="${DEBS_DIR:-debs}"
RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG required}"
SITE_DIR="${SITE_DIR:-site}"
KEY_ID="${KEY_ID:?KEY_ID required (GPG signing key id)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
mkdir -p "$SITE_DIR"
SITE_DIR="$(cd "$SITE_DIR" && pwd)"

command -v apt-ftparchive >/dev/null || { echo "missing apt-ftparchive (apt-utils)" >&2; exit 1; }
command -v gpg >/dev/null || { echo "missing gpg (gnupg)" >&2; exit 1; }
command -v xz >/dev/null || { echo "missing xz (xz-utils)" >&2; exit 1; }

echo "==> Cleaning $SITE_DIR"
rm -rf "$SITE_DIR"/*
mkdir -p "$SITE_DIR"

echo "==> Staging debs from $DEBS_DIR"
DEB_COUNT=0
for deb in "$DEBS_DIR"/*.deb; do
  [ -f "$deb" ] || continue
  if [ -e "$SITE_DIR/$(basename "$deb")" ]; then
    echo "duplicate package name $(basename "$deb") in $DEBS_DIR" >&2
    exit 1
  fi
  cp "$deb" "$SITE_DIR/"
  DEB_COUNT=$((DEB_COUNT + 1))
done
if [ "$DEB_COUNT" -eq 0 ]; then
  echo "no .deb files found in $DEBS_DIR, refusing to publish an empty index" >&2
  exit 1
fi
echo "    staged $DEB_COUNT debs ($(du -sh "$SITE_DIR" | cut -f1))"

echo "==> Generating Packages (flat)"
cd "$SITE_DIR"
apt-ftparchive packages . > Packages.tmp
# Flat repo: Filename must be a bare basename relative to the repo root
sed -E "s|^Filename: \.//*|Filename: |" Packages.tmp > Packages
rm -f Packages.tmp
if grep -qE '^Filename: [./]' Packages; then
  echo "Filename rewrite failed, apt can only join base URI + relative Filename:" >&2
  grep -E '^Filename: [./]' Packages >&2
  exit 1
fi
if [ "$(grep -c '^Filename: ' Packages)" -ne "$DEB_COUNT" ]; then
  echo "Packages lists $(grep -c '^Filename: ' Packages) entries for $DEB_COUNT staged debs" >&2
  exit 1
fi
gzip -9 -c Packages > Packages.gz
xz -9 -c Packages > Packages.xz

echo "==> Generating Release"
cat > apt-ftparchive.conf <<EOF
APT::FTPArchive::Release::Origin "GitHub Releases gfx906";
APT::FTPArchive::Release::Label "gfx906";
APT::FTPArchive::Release::Suite "stable";
APT::FTPArchive::Release::Codename "gfx906";
APT::FTPArchive::Release::Architectures "amd64";
EOF
apt-ftparchive release -c apt-ftparchive.conf . > Release
rm -f apt-ftparchive.conf

echo "==> Signing (key $KEY_ID)"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --clearsign -o InRelease Release
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --detach-sign --armor -o Release.gpg Release

echo "==> Copying pubkey / landing page"
if [ ! -f "$REPO_ROOT/pubkey.asc" ]; then
  echo "missing $REPO_ROOT/pubkey.asc, apt clients could not verify the repo" >&2
  exit 1
fi
cp "$REPO_ROOT/pubkey.asc" "$SITE_DIR/pubkey.asc"
if [ -f "$REPO_ROOT/index.html" ]; then
  cp "$REPO_ROOT/index.html" "$SITE_DIR/index.html"
fi

echo "==> Done"
find "$SITE_DIR" -maxdepth 1 -type f | sort | sed "s|$SITE_DIR/||"
