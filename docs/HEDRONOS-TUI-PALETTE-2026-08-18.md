---
artifact_id: HEDRONOS-TUI-PALETTE-2026-08-18
name: HedronOS TUI — ratatui palette, chrome, boot + home
type: report
doc_class: academy-visual
domain: academy
status: DRAFT
created: 2026-08-18
author: Sati
authority: Eli-pass / visual law for HedronOS
capital_zero: none
parent: HEDRONOS-PLAN-2026-08-18
canon:
  - HEDRONITE-DESIGN-SYSTEM.md
  - HEDRONITE-POLYHEDRON-VISUAL-LANGUAGE.md
  - HEDRONITE-AETHER-THEME.md
---
<!-- hal:authoritative:yaml -->

# HedronOS TUI visual law

This is a terminal OS. It is not a docker dashboard and not a ratatui demo.

Tokens come from `HEDRONITE-DESIGN-SYSTEM.md`. Geometry language comes from the polyhedron file: copper is the edge, lapis is the vertex, the pane is glass (dark, quiet). HedronOS is the lived-in register (patina copper), not the landing-page shine.

I do not invent the lab CLI, compose, or bindings. Marci's screen map and keys stand. Jupi owns the crate and the kernel service. This file is palette, chrome, boot, and home.

## Refuse

- Default ratatui look: yellow `Block` titles, `Color::Cyan` outlines, green-on-black status, magenta anything.
- Purple. Retired 2026-05-25. `#9b6dd8` does not ship.
- Plasma `#5ad6e0` as chrome. That is SecOps, not the OS outline.
- The word `docker`, `compose`, `container`, or `k3s` in any visible string.
- A Burst meter, dual health bars, or fighter HUD leftover.
- Fake Flower-of-Life in ASCII. FoL is a whisper on the web. In a tty it becomes noise. Lapis ticks carry that job.
- A sixth console. Home has five rooms. The sixth cell is a mark, not a room.

## Palette (ratatui `Color::Rgb`)

Map tokens. Do not hard-code a second set.

| Token | Hex | Rgb | Role on this OS |
|---|---|---|---|
| `--bg` | `#0a0a0e` | `10, 10, 14` | Floor. `Clear` / full-frame fill. |
| `--bg-panel` | `#10121a` | `16, 18, 26` | Unfocused pane fill. |
| `--bg-panel-elevated` | `#161927` | `22, 25, 39` | Focused pane fill. |
| `--copper` | `#b87333` | `184, 115, 51` | Brand. Focused `Block` border. Wordmark. Primary action. |
| `--copper-patina` | `#a06628` | `160, 102, 40` | Idle copper (HedronOS, not landing). Titles at rest. |
| `--regent-grey` | `#809DAF` | `128, 157, 175` | Secondary / italic-equivalent. Feed freshness. Dim emphasis. |
| `--lapis-lazuli` | `#1e3a8a` | `30, 58, 138` | Vertex. Ready tick. Live process. Boot POST dots. |
| `--text-primary` | `#e8e8ed` | `232, 232, 237` | Body. |
| `--text-secondary` | `#a8b0c0` | `168, 176, 192` | Supporting. |
| `--text-muted` | `#6b7280` | `107, 114, 128` | Labels, keys, row counts. |
| `--border-subtle` | `#1f2335` | `31, 35, 53` | Idle `Block` border. |
| `--border-strong` | `#2d3450` | `45, 52, 80` | Nested rule inside a focused pane. |
| `--aether-accent` | `#2E8B57` | `46, 139, 87` | Attach = yes only. One bit. Not a theme. |
| `--wood-accent` | `#8db080` | `141, 176, 128` | Lattice demo-row hint, if a domain mark is needed. |
| `--fire-accent` | `#d97757` | `217, 119, 87` | Fault. Dead-VM and failed POST. Not green/red traffic lights. |

Element accents stay in the crate as a table for later room marks (Lessons / Lab / Lattice). Home tiles this pass use copper / lapis / muted only. Do not rainbow the launcher.

Truecolor (`Rgb`) is required. 16-color fallback, if we ever need one: copper → Yellow, lapis → Blue, regent → Gray, fire → Red, floor → Black. Do not design for that first.

## Chrome

`Block` is the only chrome. `impl Widget for &T` (ratatui 0.26+). No owned-widget clones.

| State | Border | Title | Fill |
|---|---|---|---|
| idle | `border-subtle` | patina copper, muted | `--bg-panel` |
| focus | copper | copper | `--bg-panel-elevated` |
| live | copper + one lapis vertex | copper | elevated |
| fault | fire | fire | `--bg-panel` |

Vertex: a single `◆` (or `●` if the font is poor) in the top-right of the focused/live `Block`. Lapis. This is the glowing stone, not a spinner.

Title style: Geist Mono in the real world; in the tty it is whatever monospace they have. Uppercase, letter-spacing by using single spaces between letters only on the wordmark. Room titles are plain uppercase words: `LESSONS` `LAB` `LATTICE` `TOMES` `ATTACH`. No `SYS:ONLINE`. No Techartist cosplay.

Keys (Marci): render in muted on the status line, not as a help footer that eats a third of the frame. `h l r d t a q` plus `esc`.

## Pane rhythm

φ, cheap.

- Content width : chrome (borders + status) aims at 1.618 on a wide tty. Do not crush copy to hit the ratio.
- Live lapis tick breathes on a ~5s period, ramp 0.618 then decay. One vertex, not a row of blinkers.
- If two processes are live, phase them apart. Never sync-blink.
- Home tiles: focused tile is the only elevated fill. The others stay `--bg-panel`.

## Status bar

One line. Always. Bottom. Not a second window.

```
HEDRONOS 0.1    lattice 12    feed 2h    attach ·      h l r d t a q
```

| Field | Color |
|---|---|
| `HEDRONOS 0.1` | copper |
| `lattice N` | muted (count is secondary) |
| `feed …` | regent-grey if fresh, muted if stale, fire if never |
| `attach` | aether if yes, muted `·` if no |
| keys | muted |

No `BURST`. No dual bars. One meter later if the kernel ever exposes RC-like budget. Not this pass.

## Screen: Boot

Full-frame. No `Block`. No status bar. Floor is `--bg`.

Feel: firmware POST. Not a spinner over logs.

```
                         HEDRONOS
                           0.1

                      student lab
                     not the mesh

                   ◆  runtime     ok
                   ◆  kernel      waiting
                   ◆  vault       mounting
```

Wordmark `HEDRONOS` is copper, centered. `0.1` is patina. The two lines under it are regent-grey italic if the tty has italic, else regent-grey. POST labels muted, values primary. Each `◆` starts muted, turns lapis when that step passes, fire if it fails. φ-phase the diamonds; they do not blink together.

Sequence (Marci): detect runtime → wait `GET /ready` → mount vault path → Home.

Copy I own. Use this, not the plan placeholder.

On success the frame holds one beat on `ready` (lapis), then Home. No fade library. Clear and draw.

### Dead (VM off)

Still Boot. Still no chrome. One fact, one action.

```
                         HEDRONOS
                           0.1

                 HedronVM is powered off

                      [ power on ]
```

`[ power on ]` is copper, focused. Enter runs Marci's power-on (compose under the glass). Do not print brew, docker, or install help into this frame. `install.sh` already did the long path.

If power-on fails: the same frame, fire on the action, one muted line under it (`runtime missing`). Still no log dump.

## Screen: Home

The desktop. The only launcher. Everything else is a room.

Wide tty (≥ 100 cols): 2×3 grid.

```
┌ LESSONS     ◆ ┐ ┌ LAB            ┐ ┌ LATTICE       ┐
│ feed        │ │ runner         │ │ disk          │
│             │ │                │ │               │
└─────────────┘ └────────────────┘ └───────────────┘
┌ TOMES         ┐ ┌ ATTACH         ┐ ┌               ┐
│ checklist     │ │ your bot       │ │    H  0.1     │
│               │ │                │ │               │
└───────────────┘ └────────────────┘ └───────────────┘
HEDRONOS 0.1    lattice 12    feed 2h    attach ·      h l r d t a q
```

Narrow tty (< 100 cols): one column, same five rooms, sigil cell dropped. Status stays one line.

Five rooms only: Lessons, Lab, Lattice, Tomes, Attach. The sixth cell is a quiet mark (`H  0.1` in patina). It is not selectable. Do not invent a sixth console to fill the grid.

Focus is copper-edged and elevated. Selection wraps. Enter / the Marci key opens the room.

Tile body is two muted lines max (what the room is). No gauges, no fake CPU, no container health.

## Rooms (chrome only)

Same `Block` law. I am not specifying Lesson HTML or the `lab` contract.

- Lessons / Lab / Lattice / Tomes / Attach: title uppercase, copper when focused.
- Lab while a job runs: lapis vertex on the Lab `Block`, stdout in primary, stderr in fire.
- Attach with no bot: a waiting tty, not a settings form. Cursor in copper. Prompt in muted.
- Esc: Home. `q`: quit. Compose stays up (Marci). No shutdown splash this pass.

## Crate notes for Jupi (visual only)

When the crate exists, put tokens in `crates/hedronos/src/widgets/theme.rs` (name is a suggestion, not a CLI). `Color::Rgb` constants named after the design tokens. Widgets implement `Widget for &T`. `Block` for every room. Boot is a free widget, no `Block`.

Throw the `ratatui/templates` chrome away the same day it is generated.

## Hold

No GitHub repo. No k3s. No PDFs in the image. Academy is not Foundry. No palette invention in Marci's plan; this file is the palette. Review Jupi's crate and Marci's screen map when they move. I do not compose.

Sati — 2026-08-18
