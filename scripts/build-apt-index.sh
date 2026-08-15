#!/usr/bin/env bash
#
# Build a Debian/apt repository index from .deb files hosted as GitHub
# Release assets. Output layout (served by GitHub Pages):
#
#   site/
#     dists/<distribution>/main/binary-amd64/Packages{,.gz,.xz,.zst}
#     dists/<distribution>/Release
#     dists/<distribution>/InRelease
#     dists/<distribution>/Release.gpg
#     pubkey.asc
#     index.html
#
# Packages "Filename:" entries point at absolute GitHub Release asset URLs,
# so the .deb payload lives in Releases (up to 2 GB per file) while the
# (small) index lives on Pages. apt verifies SHA256 from Packages and
# follows the github.com -> release-assets.githubusercontent.com redirect.
#
# Env: DEBS_DIR, DISTRIBUTION, RELEASE_TAG, BASE_URL, SITE_DIR, KEY_ID
set -euo pipefail

DEBS_DIR="${DEBS_DIR:-debs}"
DISTRIBUTION="${DISTRIBUTION:-noble}"
RELEASE_TAG="${RELEASE_TAG:?RELEASE_TAG required}"
BASE_URL="${BASE_URL:?BASE_URL required (e.g. https://github.com/owner/repo/releases/download)}"
SITE_DIR="${SITE_DIR:-site}"
KEY_ID="${KEY_ID:?KEY_ID required (GPG signing key id)}"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

ARCH=amd64

command -v apt-ftparchive >/dev/null || { echo "missing apt-ftparchive (apt-utils)"; exit 1; }
command -v gpg >/dev/null || { echo "missing gpg (gnupg)"; exit 1; }

echo "==> Cleaning $SITE_DIR"
rm -rf "$SITE_DIR"
mkdir -p "$SITE_DIR"
# absolute, so the "cd $SITE_DIR" below can not turn later paths into no-ops
SITE_DIR="$(cd "$SITE_DIR" && pwd)"
DISTS="$SITE_DIR/dists/$DISTRIBUTION"
BIN="$DISTS/main/binary-$ARCH"
mkdir -p "$BIN" "$SITE_DIR/pool"

echo "==> Staging debs from $DEBS_DIR"
DEB_COUNT=0
for deb in "$DEBS_DIR"/*.deb; do
  [ -f "$deb" ] || continue
  if [ -e "$SITE_DIR/pool/$(basename "$deb")" ]; then
    echo "duplicate package name: $(basename "$deb")" >&2
    exit 1
  fi
  cp "$deb" "$SITE_DIR/pool/"
  DEB_COUNT=$((DEB_COUNT + 1))
done
if [ "$DEB_COUNT" -eq 0 ]; then
  echo "no .deb files found in $DEBS_DIR, refusing to publish an empty index" >&2
  exit 1
fi
echo "    staged $DEB_COUNT debs ($(du -sh "$SITE_DIR/pool" | cut -f1))"

echo "==> Generating Packages"
cd "$SITE_DIR"
apt-ftparchive packages ./pool > Packages.tmp
# Rewrite relative pool paths to absolute GitHub Release asset URLs
sed -E "s|^Filename: \.//*pool/|Filename: $BASE_URL/$RELEASE_TAG/|" Packages.tmp > "$BIN/Packages"
rm -f Packages.tmp
# Any leftover relative path would make apt fetch from Pages instead of Releases
if grep -qE '^Filename: \.?/' "$BIN/Packages"; then
  echo "Filename rewrite failed, relative paths left in Packages:" >&2
  grep -E '^Filename: \.?/' "$BIN/Packages" >&2
  exit 1
fi
gzip -9 -c "$BIN/Packages" > "$BIN/Packages.gz"
if command -v xz >/dev/null; then
  xz -9 -c "$BIN/Packages" > "$BIN/Packages.xz"
else
  echo "    xz not found, skipping Packages.xz"
fi
if command -v zstd >/dev/null; then
  zstd -q -c "$BIN/Packages" > "$BIN/Packages.zst"
else
  echo "    zstd not found, skipping Packages.zst"
fi

echo "==> Generating Release"
cat > apt-ftparchive.conf <<EOF
APT::FTPArchive::Release::Origin "GitHub Pages gfx906";
APT::FTPArchive::Release::Label "gfx906";
APT::FTPArchive::Release::Suite "$DISTRIBUTION";
APT::FTPArchive::Release::Codename "$DISTRIBUTION";
APT::FTPArchive::Release::Architectures "$ARCH";
APT::FTPArchive::Release::Components "main";
EOF
apt-ftparchive release -c apt-ftparchive.conf "$DISTS" > "$DISTS/Release"
rm -f apt-ftparchive.conf

echo "==> Signing (key $KEY_ID)"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --clearsign -o "$DISTS/InRelease" "$DISTS/Release"
gpg --batch --yes --pinentry-mode loopback --passphrase '' \
  -u "$KEY_ID" --detach-sign --armor -o "$DISTS/Release.gpg" "$DISTS/Release"

echo "==> Dropping payload (debs stay in Releases, not Pages)"
rm -rf "$SITE_DIR/pool"
if [ -e "$SITE_DIR/pool" ]; then
  echo "failed to drop $SITE_DIR/pool, refusing to publish deb payload to Pages" >&2
  exit 1
fi

echo "==> Copying pubkey / landing page"
if ! [ -f "$REPO_ROOT/pubkey.asc" ]; then
  echo "missing $REPO_ROOT/pubkey.asc, apt clients could not verify the repo" >&2
  exit 1
fi
cp "$REPO_ROOT/pubkey.asc" "$SITE_DIR/pubkey.asc"
if [ -f "$REPO_ROOT/index.html" ]; then
  cp "$REPO_ROOT/index.html" "$SITE_DIR/index.html"
else
  echo "    no index.html, skipping landing page"
fi

echo "==> Done"
find "$SITE_DIR" -type f | sort
