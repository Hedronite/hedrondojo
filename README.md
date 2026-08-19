# HedronOS student lab

Not the mesh. A laptop lab: one kernel container (SQLite + DuckDB + lesson fetch + `lab` CLI) and HedronOS, the TUI they sit at.

Lives under `ideas/academy/`. No GitHub repo this pass.

## Install

```bash
./install.sh
```

That brings the kernel up on `127.0.0.1:18800` and execs `hedronos` so the first screen is Boot.

```bash
./install.sh --headless   # skip Obsidian and the TUI (cloud later)
```

Re-open is `hedronos`. The kernel stays up.

Lessons feed: https://hedronite.com (main, not staging).

Bot attach: open this folder, then `@hedronite-lab` (see `skill.md`).

## Holds

- No tofu/ this pass
- No tome PDFs (checklist only: `checklists/tomes.md`)
- No Tailscale, no mesh IPs, no k3s, no Redis, no Gemma
- Do not host this on citadel or apiary
- Localhost only. 8 GB laptop floor
- Schema + demo rows only — not Evan's Akasha
- Visual law is Sati's; this stub uses default ratatui

## Layout

See `LAYOUT.md`.
