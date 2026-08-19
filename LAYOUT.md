# LAYOUT

Authority: Marci `HEDRONOS-PLAN-2026-08-18` (OS map). Sati visual law. Eli: playable crate now.

## Kernel (compose service `kernel`)

One service. Bind `127.0.0.1:18800:18800`.

Volumes:

- `./seed:/var/hedron/seed:ro`
- `lab-data:/var/hedron/data`
- `./vault:/var/hedron/vault`

Env: `LESSONS_FEED=https://hedronite.com`, `LATTICE_DB=/var/hedron/data/lattice.db`, `HEDRON_KERNEL=http://127.0.0.1:18800`. `mem_limit: 2g`.

First boot copies `seed/lattice.db` into the data volume if that volume is empty. The repo seed is not mutated.

HedronOS is host-side. It is not in the image.

## Kernel contract (as implemented)

Unversioned HTTP on localhost. `python -m lab serve` binds `0.0.0.0:18800`.

| method | path | result |
|--------|------|--------|
| GET | `/ready` | 200 `{"ok":true,"version":"0.1","lattice_rows":N,"feed_fetched_at":null\|iso}` once the db is open. Does **not** wait on the network. 503 if the db is missing. |
| GET | `/lessons` | `{"lessons":[{id,url,title,body_text,fetched_at,cached}]}`. Bodies are seed demo titles (2–3). `https://hedronite.com` is a freshness ping only — the homepage is **not** a lesson. Seed rows if the ping fails. |
| POST | `/jobs` | Body `{"job":"demo"}` or `{"lesson_id":N}`. One at a time. 200 `{"job","stdout","stderr","exit"}`. 409 `{"error":"busy"}`. Demo prints `lab demo ok`. No SSE. |

CLI: `python -m lab fetch|status|query|serve`.

## install.sh

Last step (unless `--headless`): exec `hedronos` (release binary if built, else `cargo run --manifest-path crates/hedronos/Cargo.toml`). `--headless` skips Obsidian and the TUI.

## Crate (`crates/hedronos`)

Package + binary `hedronos`. Edition 2021. ratatui 0.29, crossterm 0.28. std HTTP to the kernel (no extra client crate).

```
src/main.rs
src/os.rs              Console {Boot, Home, Lessons, Lab, Lattice, Tomes, Attach}
src/kernel.rs          GET /ready, GET /lessons, POST /jobs; silent power-on
src/consoles/          boot home lessons lab lattice tomes attach
src/widgets/theme.rs   Color::Rgb tokens from Sati
src/widgets/chrome.rs  Block idle/focus/live/fault + lapis vertex
```

`impl Widget for &T`. Visible strings never say docker / compose / container / k3s.

## Assumptions

- Ready is **GET /ready**, not POST. Boot's "POST" is firmware copy (detect runtime → kernel → vault).
- Seed db is copied onto the data volume on first boot; repo `seed/lattice.db` stays read-only from the kernel's point of view.
- Homepage `https://hedronite.com` is not a lesson document.
- `lab/__main__.py` exists so `python -m lab` runs (not listed in the tree sketch; required by the module contract).
- Lattice console shows canned table/demo names this pass (no rusqlite in the TUI).
