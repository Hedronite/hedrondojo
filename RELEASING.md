# Releasing hedronite-lab (HedronOS side)

Merge law: PRs wait for Evan. The tag is Evan's.

## What a tag does

`git tag v0.1.0 && git push origin v0.1.0` runs `.github/workflows/release.yaml`:

1. Builds the kernel image for `linux/amd64` + `linux/arm64` and pushes
   `ghcr.io/<namespace>/hedronos-kernel:v0.1.0` and `:latest`.
2. Builds `hedronos` for darwin/linux × arm64/amd64 and attaches
   `hedronos-<platform>` and `hedronos-<platform>.sha256` to the GitHub Release.

`install.sh` reads `VERSION` to pick both the image tag and the release asset.
Bump `VERSION` in a PR before cutting the matching tag.

## One-time setup (Evan)

The repo lives under the `VirtualMachinist` account. The locked image name is
`ghcr.io/hedronite/hedronos-kernel`. `GITHUB_TOKEN` can only publish into the repo
owner's namespace, so pick one:

- **Hedronite org namespace (locked default).** Add repository secrets `GHCR_USERNAME`
  (a Hedronite org member) and `GHCR_TOKEN` (classic PAT with `write:packages`).
- **Account namespace (no secrets).** Set repository variable
  `GHCR_NAMESPACE=virtualmachinist`. Then change the default
  `HEDRONOS_KERNEL_IMAGE` in `compose.yaml` to `ghcr.io/virtualmachinist/hedronos-kernel`.

After the first push, open the package settings on GitHub and set visibility to
**Public**. GitHub has no API for this; it is a one-time click. Strangers get
`denied` on pull until it is done.

## Verify after the tag

```bash
docker pull ghcr.io/hedronite/hedronos-kernel:v0.1.0
scripts/smoke-oneclick.sh     # timed stranger DoD in a throwaway HOME
```

## Before the tag exists

The smoke can run against a local kernel image and binary:

```bash
docker build -t ghcr.io/hedronite/hedronos-kernel:v0.1.0 .
cargo build --release --manifest-path crates/hedronos/Cargo.toml
HEDRONOS_BINARY=$PWD/crates/hedronos/target/release/hedronos \
INSTALL_SH=./install.sh HEDRONOS_REF=<branch> scripts/smoke-oneclick.sh
```
