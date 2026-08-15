# Deployment plan — move ML-gfx906 apt repo from homelab to GitHub

Goal: mixa3607 hosts gfx906 build artifacts on a homelab (`s3.arkprojects.space`,
reached via scp from CI). This POC mirrors the repo and serves the apt repo
entirely from GitHub: **code on GitHub, `.deb` payload on GitHub Releases,
apt index on GitHub Pages**. No infrastructure to maintain, $0, HTTPS by
default.

## Current state (verified 2026-08-15)

- Source repo: 460 KB of build recipes (Dockerfiles, patches, scripts), `master` branch.
- Apt repo (homelab S3, aptly-generated): `dists/noble`, amd64, main. 145 debs,
  ~1.45 GB total per build set. Largest deb: `amdrocm-dnn7.14-gfx906` 325 MB.
- 30 timestamped releases (e.g. `20260802001858`), zero assets — tags exist as
  reproducible build refs. S3 repo holds the **rolling latest** build set only.
- CI pushes debs to homelab via scp (`k3s@kube-worker6.arkprojects.lan`), images
  to Docker Hub.

## Target architecture

```
GitHub repo phantomic12/ML-gfx906
├── master        build recipes (mirror of upstream)
├── Pages         dists/noble/... index (few hundred KB)  ← apt sources point here
└── Releases      *.deb assets (up to 2 GB each)           ← payload, per timestamp tag

User machine:
  deb https://phantomic12.github.io/ML-gfx906 noble main
      └─ apt fetches Packages (Pages) → downloads .deb (Release URL, 302 to CDN)
         → verifies SHA256 → installs
```

## Why not Pages-only

- git hard-caps files at 100 MB per push; Pages caps published sites at 1 GB.
  325 MB debs can't live in git, and one build set alone exceeds the Pages site cap.
- Releases allow 2 GB per asset. Hence the split.

## Why not Releases-only

- apt needs a `dists/<suite>/.../Packages` tree. You can stuff the index into a
  release, but then every release must re-upload the whole index and the
  sources URL is version-specific. Pages gives a stable, canonical URL.

## Migration steps

1. ✅ Create `phantomic12/ML-gfx906`, enable Pages (Actions build type).
2. ✅ Mirror upstream code onto `master` (plain clone → push, history kept).
3. ✅ Add workflows + scripts (this repo's `.github/workflows/` and `scripts/`).
4. ✅ Generate apt signing key (ed25519, no passphrase). Private key → Actions
   secret `APT_GPG_PRIVATE_KEY`; id → variable `APT_KEY_ID`; public key →
   `pubkey.asc` in repo and in the Pages artifact.
5. ⏳ Migrate payload: `scripts/migrate-from-s3.sh` downloads the 145 debs
   (~1.45 GB) from homelab S3 and uploads them to release `20260802001858`.
6. ⏳ Run **Publish APT repo to GitHub Pages** workflow → index live.
7. ⏳ Verify from a clean machine: `apt-get update`, `apt-get download` a small
   package, compare SHA256, install a trivial package.

## Operations (new build set, every ~day)

1. Existing deb build workflows produce `.deb`s (they currently scp to homelab —
   upstream change: replace scp with `gh release upload`, or use
   `upload-debs-to-release.yaml`).
2. Upload to a timestamped release (e.g. `20260815235900`).
3. Index workflow regenerates Pages from that release's assets.
4. Old release can be deleted to reclaim repo storage — the index always points
   at the latest set. (Matches upstream's rolling-latest model.)

## Limits & tradeoffs (GitHub Free, public repo)

| Limit | Value | Impact |
|---|---|---|
| Release asset size | 2 GB/file | ✅ debs ≤ 325 MB |
| Repo storage | ~5 GB soft | ⚠️ ~3 full build sets before GitHub nudges. Keep rolling latest, prune old releases |
| Pages site size | 1 GB | ✅ index is KBs |
| Pages bandwidth | 100 GB/mo soft | ✅ index only; payload bandwidth is Release CDN, uncapped |
| Git file cap | 100 MB | ✅ debs never touch git |
| Download resume | Releases CDN supports ranges | ✅ |
| Rate limits | Pages 429 possible | ✅ low traffic expected |

Tradeoff vs homelab: full version history on GitHub is impractical (30 × 1.45 GB
= ~43 GB). Homelab S3 remains a fine archive; GitHub becomes the fast, reliable
distribution front for the latest build.

## Rollback

- Keep the homelab S3 repo untouched during/after migration — it's the fallback.
- Rollback = repoint user sources back at `s3.arkprojects.space`; nothing else changes.
- If a Pages deploy is bad, re-run the publish workflow with an older
  `release_tag` input; Pages deploys are atomic.

## Handoff to mixa3607

To adopt upstream (not a fork, so no PR):

1. Copy `.github/workflows/publish-apt-repo.yaml`,
   `.github/workflows/upload-debs-to-release.yaml`, `scripts/`,
   `index.html`, `pubkey.asc` into their repo.
2. Add `APT_GPG_PRIVATE_KEY` (repo secret) + `APT_KEY_ID` (repo variable).
3. Enable Pages → Source: GitHub Actions.
4. In each `build-and-push.deb.sh`: replace the `scp` block with
   `gh release upload "$RELEASE_TAG" .../*.deb --clobber` and either push a
   timestamp tag or trigger the publish workflow after upload.
5. Update README `URIs:` to `https://<owner>.github.io/<repo>`.
6. Point the homelab S3 sync job at GitHub (or retire it once the archive is
   drained).

## Verification checklist (acceptance)

- [ ] `apt-get update` succeeds with `Signed-By` keyring (no `trusted=yes`)
- [ ] `apt-get download amdrocm-rand7.14-gfx906` yields deb whose SHA256 matches `Packages`
- [ ] `apt-cache policy` shows version from GitHub index
- [ ] curl the `.deb` URL: 302 → release-assets CDN, 200 on follow
- [ ] index deploys via Actions (Pages build_type=workflow), no branch needed
