---
artifact_id: HEDRONOS-CHROME-REVIEW-2026-08-18
name: HedronOS chrome review — crate vs palette
type: report
doc_class: academy-visual
domain: academy
status: DRAFT
created: 2026-08-18
author: Sati
authority: Eli-pass / visual law
parent: HEDRONOS-TUI-PALETTE-2026-08-18
crate: ideas/academy/hedron-lab/crates/hedronos
---
<!-- hal:authoritative:yaml -->

# HedronOS chrome review

Reviewed `crates/hedronos` against `HEDRONOS-TUI-PALETTE-2026-08-18.md`. No GitHub, so Kimi (Cursor cloud) was not a tap. This is Sati on disk.

## Pass

- `theme.rs` is the design-system `Color::Rgb` table. Copper, patina, regent, lapis, fire, aether. No `Color::Cyan` / Yellow / Magenta. No purple.
- `impl Widget for &T` on Boot, Home, rooms, Attach.
- Boot has no `Block`. Wordmark + dead-VM `[ power on ]` match the spec.
- Home is 2×3 / five rooms + `H 0.1` mark on wide tty. Status is one line. No docker / compose / k3s strings.
- `lapis_tick` is φ on a 5s period.
- ratatui `=0.26.3`.

## Painted this pass

- Home no longer lies about focus (LESSONS was hard-coded copper). Tiles are idle until Marci adds selection.
- Narrow tty drops the sigil cell (spec).
- Boot POST diamonds phase by index. They do not blink as one.
- Room `Block`s get a lapis vertex.

## Holes (stop)

1. **POST is skipped.** `main` calls `step_boot()` before the first draw. If the kernel is up, Home is the first frame. Spec wants a beat on `ready`. Flow/timing is Marci + a one-line hold I will not add without her.
2. **Home has no selection.** Keys jump straight to rooms. Copper-on-focus needs `home_sel`. Bindings stay Marci.
3. **Boot POST copy is frozen** (`ok` / `waiting` / `mounting`) even on the dead path you never see it. Values should follow kernel state when POST is actually shown.
4. **Rooms are stubs.** Lessons is one URL line. Lab has no live vertex while a job runs. Fine this pass.
5. **Attach prompt line** is a placeholder (`hedronos login: _`). Marci said she writes it from `skill.md`.
6. **Kimi tap** needs a repo. None yet.

No GitHub. I did not invent CLI or compose.

Sati — 2026-08-18
