---
artifact_id: HEDRONOS-PLAYABLE-2026-08-18
name: HedronOS — Boot → Home is playable
type: report
doc_class: academy-playable
domain: academy
status: DONE
created: 2026-08-18
author: Marci
authority: Marci plan / Eli-pass student lab
capital_zero: none
parent: HEDRONOS-PLAN-2026-08-18
---
<!-- hal:authoritative:yaml -->

# HedronOS playable — Boot → Home

2026-08-18 21:29 ET. rustc 1.85.0. Not citadel, not apiary. No GitHub. Did not touch think-harvest / llama / omp.

## Paths

| where | path |
|-------|------|
| crate | `ideas/academy/hedron-lab/crates/hedronos/` |
| vault | `~/Obsidian/Atrium/Atrium/ideas/academy/hedron-lab/crates/hedronos/` |

Vault copy is Cargo.toml, Cargo.lock, `.gitignore`, and `src/**` only. No `target/`. No `.git`. No `tofu/`.

## Cargo results

`cargo test` — `boot_reaches_home`, `keys_route_rooms`, `home_starts_idle`, `ready_503_same_keys`.

`cargo run -- --smoke` — exit 0 (TestBackend, Boot → Home).

## Boot → Home

1. First frame is Boot POST (drawn before the kernel probe).
2. Probes `GET $HEDRON_KERNEL/ready` (default `http://127.0.0.1:18800`).
3. **Kernel up** (`ok: true`) → Home.
4. **503** parses the same Ready struct; stays on Boot as dead VM + error string.
5. **Unreachable** → dead VM + `[ power on ]`. No in-process demo kernel.

Home is five rooms (LESSONS LAB LATTICE TOMES ATTACH) plus `H 0.1` on wide tty. Narrow drops the mark. `home_sel` idle until l r d t a. Attach is from skill.md.

`kernel.rs` also has GET `/lessons` and POST `/jobs` with job + lesson_id. Rooms are still stubs.

## Crate notes

- ratatui **=0.26.3** + crossterm 0.27. No ureq. rustc 1.85.
- Sati palette in `widgets/theme.rs`. Phased POST diamonds via `lapis_tick_phased`.
- No purple. No docker/compose/container/k3s on screen.

## Hold

- No GitHub repo.
- No compose/install edits (Jupi's).
- Rooms stay stubs this pass.

Marci — 2026-08-18 21:34 ET
