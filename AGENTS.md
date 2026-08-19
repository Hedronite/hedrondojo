# AGENTS.md

## Cursor Cloud specific instructions

HedronOS student lab is one product delivered as two cooperating parts:

- Kernel — a pure Python 3.12 stdlib HTTP service + `lab` CLI backed by SQLite (the "lattice" DB). Code lives in `lab/`.
- HedronOS — a Rust ratatui TUI (the screen the student sits at). Code lives in `crates/hedronos/`. It talks to the kernel over localhost HTTP.

### Running the kernel (preferred dev path)

The README's canonical `./install.sh` path uses Docker Compose, but the kernel is stdlib-only Python, so in the cloud VM run it directly (no Docker needed):

```bash
python3 -m lab serve   # binds 0.0.0.0:18800; long-running, run it in a tmux session
```

- HTTP contract (localhost, unversioned): `GET /ready`, `GET /lessons`, `POST /jobs` (body `{"job":"demo"}` or `{"lesson_id":N}`; one job at a time, returns 409 `busy` if concurrent).
- The DB defaults to `seed/lattice.db` (committed, already present). Override with `LATTICE_DB`. The kernel never mutates the repo seed.
- Other env vars: `LAB_BIND` (default `0.0.0.0`), `LAB_PORT` (default `18800`), `LESSONS_FEED` (default `https://hedronite.com`, freshness ping only — network is never required; `/ready` never blocks on it).
- CLI: `python3 -m lab fetch|status|query|serve`.
- Running the CLI creates `lab/__pycache__/` — do not commit it.

Docker Compose (`./install.sh`, `compose.yaml`) also works but is heavier/more fragile in the VM; only use it when specifically validating the containerized path.

### Building and running the TUI

The crate needs Rust >= 1.85 (`crates/hedronos/Cargo.toml` sets `rust-version = "1.85"`). The base image's default 1.83 cannot build it; the update script installs and defaults to stable via rustup.

```bash
cargo build --release --manifest-path crates/hedronos/Cargo.toml
./crates/hedronos/target/release/hedronos           # full TUI (needs a real terminal)
./crates/hedronos/target/release/hedronos --smoke    # headless: boots + renders Home, exits 0
```

- The TUI reads live kernel data at boot via `HEDRON_KERNEL` (default `http://127.0.0.1:18800`). Home's status line shows `lattice <N>` and the feed timestamp; the Lattice console shows `<N> demo rows`.
- Keys: `h` home, `l` lessons, `r` lab, `d` lattice, `t` tomes, `a` attach, `q` quit.

### Lint / test — important gotcha

- Tests and the `--smoke` check require the kernel to be running first. `os::tests::boot_reaches_home` and `--smoke` both call `GET /ready`; with no kernel up they fail with "runtime missing" (an environment issue, not a code bug). Start `python3 -m lab serve`, then:

```bash
cargo test --manifest-path crates/hedronos/Cargo.toml
```

- Lint: `cargo clippy --manifest-path crates/hedronos/Cargo.toml --all-targets` and `cargo fmt --manifest-path crates/hedronos/Cargo.toml --check`. Both surface pre-existing style nits (a `clippy::io_other_error` warning and rustfmt diffs) on the newer toolchain; neither is gated/blocking. The Python kernel has no configured linter.
