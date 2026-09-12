<h1 align="center">hedronite-lab</h1>

<p align="center">
  <strong>A student OS and a devops workshop on your laptop.</strong><br>
  <em>Install once. Two verbs after: <code>hedronos</code> and <code>lab</code>.</em>
</p>

<p align="center">
  <a href="https://github.com/VirtualMachinist/hedronos"><img src="https://img.shields.io/badge/student_OS-hedronos-b87333?style=flat&colorA=0a0a0e" alt="hedronos"></a>
  <a href="https://github.com/VirtualMachinist/hedronite-devops-lab"><img src="https://img.shields.io/badge/devops_toolbox-lab-1e3a8a?style=flat&colorA=0a0a0e" alt="lab"></a>
  <a href="https://hedronite.com"><img src="https://img.shields.io/badge/lessons-hedronite.com-b87333?style=flat&colorA=0a0a0e" alt="hedronite.com"></a>
  <a href="LICENSE"><img src="https://img.shields.io/github/license/VirtualMachinist/hedronos?style=flat&colorA=0a0a0e&colorB=b87333" alt="MIT license"></a>
</p>

<p align="center">
  <a href="#quick-start">Quick start</a> ·
  <a href="#two-verbs">Two verbs</a> ·
  <a href="#what-you-get">What you get</a> ·
  <a href="#start-here">Start here</a> ·
  <a href="LAYOUT.md">Layout</a> ·
  <a href="https://github.com/VirtualMachinist/hedronite-devops-lab">Devops lab repo</a>
</p>

<p align="center">
  Built by <a href="https://hedronite.com">Hedronite</a>'s
  <a href="https://github.com/VirtualMachinist">VirtualMachinist</a>.
  Not the mesh. Not Omahedron. Not a hosted fleet.
</p>

---

**hedronite-lab** is the public install story for two tools that share your laptop:

- **`hedronos`** — a terminal student OS. Boot → Home → lessons and consoles.
- **`lab`** — a disposable devops toolbox (Terraform, kubectl, uv, Rust, …). Cattle, not pets.

This repo ships **HedronOS** (the TUI + kernel). The workshop image lives in
[`VirtualMachinist/hedronite-devops-lab`](https://github.com/VirtualMachinist/hedronite-devops-lab).
One install path wires both; you do not pick between two products.

HedronOS is **not** a cluster, mesh, or cloud control plane. It runs on **localhost** with an **8 GB RAM** floor.
The kernel listens on `127.0.0.1:18800`. Lessons feed from [hedronite.com](https://hedronite.com) (main, not staging).

## Identity

| | |
|---|---|
| **Product** | hedronite-lab |
| **Verbs** | `hedronos` (student OS) · `lab` (devops toolbox) |
| **Org (SoT)** | [VirtualMachinist](https://github.com/VirtualMachinist) |
| **This repo** | Student OS kernel + TUI |
| **Sibling repo** | [hedronite-devops-lab](https://github.com/VirtualMachinist/hedronite-devops-lab) |
| **Version** | `v0.1.0` (student OS + kernel) |
| **Agent attach** | Open this folder, then `@hedronite-lab` ([skill.md](skill.md)) |

## Quick start

**Needs:** macOS or Linux, 8 GB RAM, a container runtime (OrbStack, Docker Desktop, or Colima).

One command (VirtualMachinist is the source of truth for raw URLs):

```bash
curl -fsSL https://raw.githubusercontent.com/VirtualMachinist/hedronos/main/install.sh | bash
```

That brings up the kernel on `127.0.0.1:18800`, installs the `hedronos` binary and the `lab` shell function, then opens Boot.

```bash
hedronos              # re-open the student OS (kernel stays up)
./install.sh --headless   # kernel only — skip Obsidian and the TUI
```

**Contributor path** (same tree, no curl):

```bash
git clone https://github.com/VirtualMachinist/hedronos.git
cd hedronos
./install.sh
```

## Two verbs

After install you have exactly two commands to remember:

| Verb | What it is | When you use it |
|---|---|---|
| **`hedronos`** | Host TUI — Boot, Home, Lessons, Lab console | Daily student work; re-open anytime |
| **`lab`** | Ephemeral devops container (`ghcr.io/hedronite/lab`) | Terraform, kubectl, cert practice — throwaway runs |

The TUI may say “Lab” for the kernel console. The shell command **`lab`** is only the devops toolbox.
See the [devops-lab README](https://github.com/VirtualMachinist/hedronite-devops-lab#usage) for `lab terraform …`, `lab uv run …`, and mount options.

Install the workshop function alone (if you already have HedronOS):

```bash
source <(curl -fsSL https://raw.githubusercontent.com/VirtualMachinist/hedronite-devops-lab/main/shell/lab.zsh)
```

Add that line to `~/.zshrc` if you want `lab` in every shell.

## What you get

- A **kernel** on localhost (`GET /ready` → `{"ok":true,...}`) with SQLite lattice + lesson fetch
- **HedronOS** TUI with Boot → Home and room consoles
- **`lab`** function pulling `ghcr.io/hedronite/lab:latest` for infra practice
- Demo lesson rows and a schema-safe seed — not a personal vault

## What you do not get (v1)

- No mesh, Tailscale, k3s requirement, or remote hosting
- No tofu/ cloud apply, Redis, or Gemma in this pass
- No tome PDFs bundled ([checklists/tomes.md](checklists/tomes.md) is a checklist only)
- No MCP server over the kernel — agents attach via [skill.md](skill.md), not a second API

## Start here

| You are… | Start with… |
|---|---|
| **A new student** | [Quick start](#quick-start) → `hedronos` → Lessons room |
| **Doing cert / infra practice** | [`lab`](https://github.com/VirtualMachinist/hedronite-devops-lab) after the same install |
| **An agent** | [skill.md](skill.md) — `@hedronite-lab` when the kernel is up |
| **A contributor** | [LAYOUT.md](LAYOUT.md) — kernel contract, crate map, chrome law |

## Holds

- Localhost only · 8 GB laptop floor
- Do not host this kernel on shared build machines
- Schema + demo rows only
- Visual chrome follows academy palette law (copper / lapis / floor `#0a0a0e`)

## Layout

Kernel, HTTP contract, crate tree, and install behavior: [LAYOUT.md](LAYOUT.md).
