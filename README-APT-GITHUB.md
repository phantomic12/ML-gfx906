# gfx906 apt repo on GitHub (Releases + Pages)

This repo mirrors [mixa3607/ML-gfx906](https://github.com/mixa3607/ML-gfx906) and
demonstrates hosting its apt repository entirely on GitHub — no homelab, no S3,
no server. **Flat apt repo in GitHub Releases, key/docs on GitHub Pages.**

## Why a flat repo (`deb URL ./`)

| Thing | Host | Reason |
|---|---|---|
| `.deb` files (up to ~325 MB each, ~1.4 GB per build set) | GitHub **Releases** | git caps files at 100 MB; Pages caps sites at 1 GB. Release assets allow up to 2 GB each |
| `Packages`, `Release`, `InRelease` (few hundred KB) | GitHub **Releases** (flat) | apt cannot fetch absolute `Filename:` URLs — it joins `base URI + Filename`. Flat format (`deb URL ./`) makes apt fetch `Packages`/`InRelease` at the repo root, which matches GitHub's flat release assets exactly |
| Signing key | repo **Actions secret** | `InRelease` signed so `apt update` verifies the repo |

apt fetches `https://github.com/.../releases/download/<tag>/Packages`,
follows the github.com → release-assets CDN redirect, and verifies each
download against the SHA256 in `Packages`.

## Add the repository (Ubuntu 24.04)

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://phantomic12.github.io/ML-gfx906/pubkey.asc -o /etc/apt/keyrings/apt-gfx906.asc
sudo chmod a+r /etc/apt/keyrings/apt-gfx906.asc
sudo tee /etc/apt/sources.list.d/gfx906.sources <<EOF
Types: deb
URIs: https://github.com/phantomic12/ML-gfx906/releases/download/20260802001858
Suites: ./
Signed-By: /etc/apt/keyrings/apt-gfx906.asc
EOF
sudo apt-get update
```

One-line form: `deb [signed-by=/etc/apt/keyrings/apt-gfx906.asc] https://github.com/phantomic12/ML-gfx906/releases/download/20260802001858 ./`

> **Rolling latest:** for a moving `latest` tag (delete+recreate per build set),
> use `URIs: .../releases/download/latest` instead. See DEPLOYMENT-PLAN.md.

## Publishing a new build set

1. Build debs (existing build workflows, or `upload-debs-to-release.yaml`
   with `release_tag` + `deb_paths` inputs).
2. Run **Publish APT repo to GitHub Releases** workflow — it downloads the
   `.deb` assets, regenerates `Packages`/`Release`/`InRelease` (flat), signs,
   uploads the index files back into the same release, and deploys Pages
   (pubkey + landing page).

## Files

- `.github/workflows/publish-apt-repo.yaml` — index build + upload + Pages deploy
- `.github/workflows/upload-debs-to-release.yaml` — manual deb → release helper
- `scripts/build-apt-index.sh` — flat index generator (apt-ftparchive + gpg)
- `scripts/migrate-from-s3.sh` — one-shot pull of the homelab S3 repo
- `DEPLOYMENT-PLAN.md` — full plan, limits, rollback, upstream handoff
