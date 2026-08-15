# gfx906 apt repo on GitHub (Pages + Releases)

This repo mirrors [mixa3607/ML-gfx906](https://github.com/mixa3607/ML-gfx906) and
demonstrates hosting its apt repository entirely on GitHub — no homelab, no S3,
no server. **Index on GitHub Pages, package payload on GitHub Releases.**

## Why this split

| Thing | Host | Reason |
|---|---|---|
| `.deb` files (up to ~325 MB each, ~1.4 GB per build set) | GitHub **Releases** | git repo caps files at 100 MB; Pages caps sites at 1 GB. Release assets allow up to 2 GB each |
| `Packages`, `Release`, `InRelease` (few hundred KB) | GitHub **Pages** | apt needs a static `dists/` tree over HTTPS; Pages serves it for free |
| Signing key | repo **Actions secret** | `InRelease` signed so `apt update` verifies the repo |

`Packages` entries carry absolute `Filename:` URLs pointing at
`https://github.com/phantomic12/ML-gfx906/releases/download/<tag>/<file>.deb`.
apt follows the github.com → release-assets.githubusercontent.com redirect and
verifies each download against the SHA256 recorded in `Packages`.

## Repository layout

```
dists/noble/main/binary-amd64/Packages{,.gz,.xz,.zst}   <- served by Pages (.zst when the runner has zstd)
dists/noble/{Release,InRelease,Release.gpg}
pubkey.asc                                               <- signing public key
index.html

releases/download/<tag>/*.deb                            <- payload on Releases
```

## Add the repository (Ubuntu 24.04)

```bash
sudo apt-get update
sudo apt-get install ca-certificates curl -y
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://phantomic12.github.io/ML-gfx906/pubkey.asc -o /etc/apt/keyrings/apt-gfx906.asc
sudo chmod a+r /etc/apt/keyrings/apt-gfx906.asc
sudo tee /etc/apt/sources.list.d/gfx906.sources <<EOF
Types: deb
URIs: https://phantomic12.github.io/ML-gfx906
Suites: noble
Components: main
Architectures: $(dpkg --print-architecture)
Signed-By: /etc/apt/keyrings/apt-gfx906.asc
EOF
sudo apt-get update
```

Same shape as the original S3 instructions — only the `URIs` line changed. `Suites` is
pinned to `noble` because the index is built for that suite only; publishing another
suite means running the workflow with a different `distribution` input.

## Publishing a new build set

1. Build debs (existing build workflows, or `upload-debs-to-release.yaml`
   workflow with `release_tag` + `deb_paths` inputs).
2. `gh release upload <tag> path/to/*.deb`
3. Run **Publish APT repo to GitHub Pages** workflow. It downloads the `.deb`
   assets, regenerates `Packages`/`Release`, signs, deploys Pages. Run it *after*
   the assets are uploaded — indexing a release with no assets yet would publish
   an empty repository.

## Files

- `.github/workflows/publish-apt-repo.yaml` — index build + Pages deploy
- `.github/workflows/upload-debs-to-release.yaml` — manual deb → release helper
- `scripts/build-apt-index.sh` — the index generator (apt-ftparchive + gpg)
- `scripts/migrate-from-s3.sh` — one-shot pull of the homelab S3 repo
- `DEPLOYMENT-PLAN.md` — full plan, limits, rollback, upstream handoff
