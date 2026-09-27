# Changelog

## Unreleased

### Rename: HedronOS to HedronDojo

This product is **HedronDojo**, a DevOps training app and lab image. The repository is [github.com/Hedronite/hedrondojo](https://github.com/Hedronite/hedrondojo). The name HedronOS now belongs to a different product, the flagship OS.

Backward-compatible shims:

- The `hedronos` command prints a deprecation warning to stderr and forwards to `hedrondojo`. `install.sh` installs that wrapper next to the real binary. It is a shell script (`scripts/hedronos`), not a release asset.
- `HEDRONOS_*` environment variables are still read when the matching `HEDRONDOJO_*` variable is unset. `install.sh` and `scripts/smoke-oneclick.sh` print a deprecation warning. `compose.yaml` chains `${HEDRONDOJO_*:-${HEDRONOS_*:-default}}` for the kernel image, tag, and port.

There are no earlier changelog entries in this repo. Wording in this entry is the record of the rename; do not rewrite it to drop the old names.
