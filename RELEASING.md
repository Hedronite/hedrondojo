# Releasing hedronite-lab (HedronDojo)

Merge law: PRs wait for Evan. The tag is Evan's.

## What a tag does

`git tag v0.1.0 && git push origin v0.1.0` runs `.github/workflows/release.yaml`:

1. Builds the kernel image for `linux/amd64` + `linux/arm64` and pushes
   `ghcr.io/<namespace>/hedrondojo-kernel:v0.1.0` and `:latest`.
2. Builds `hedrondojo` for darwin/linux × arm64/amd64 and attaches
   `hedrondojo-<platform>` and `hedrondojo-<platform>.sha256` to the GitHub Release.

`install.sh` reads `VERSION` to pick both the image tag and the release asset.
Bump `VERSION` in a PR before cutting the matching tag.

## One-time setup (Evan)

The repo is [`Hedronite/hedrondojo`](https://github.com/Hedronite/hedrondojo). The locked image name is
`ghcr.io/hedronite/hedrondojo-kernel`. `GITHUB_TOKEN` publishes into the repo
owner's namespace (`hedronite`), which matches that image.

To publish into a different namespace, set repository variable `GHCR_NAMESPACE`
and point `HEDRONDOJO_KERNEL_IMAGE` in `compose.yaml` at that namespace
(for example `ghcr.io/virtualmachinist/hedrondojo-kernel`).

After the first push, open the package settings on GitHub and set visibility to
**Public**. GitHub has no API for this; it is a one-time click. Strangers get
`denied` on pull until it is done.

## Verify after the tag

```bash
docker pull ghcr.io/hedronite/hedrondojo-kernel:v0.1.0
scripts/smoke-oneclick.sh     # timed stranger DoD in a throwaway HOME
```

## Before the tag exists

The smoke can run against a local kernel image and binary:

```bash
docker build -t ghcr.io/hedronite/hedrondojo-kernel:v0.1.0 .
cargo build --release --manifest-path crates/hedrondojo/Cargo.toml
HEDRONDOJO_BINARY=$PWD/crates/hedrondojo/target/release/hedrondojo \
INSTALL_SH=./install.sh HEDRONDOJO_REF=<branch> scripts/smoke-oneclick.sh
```
