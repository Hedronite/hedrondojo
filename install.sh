#!/usr/bin/env bash
# hedronite-lab installer — HedronDojo (training app + kernel) and the lab toolbox.
#
#   curl -fsSL https://raw.githubusercontent.com/Hedronite/hedrondojo/main/install.sh | bash
#
# Stranger path: no git, no cargo, no python on the host. Needs curl, tar, and a
# container runtime (OrbStack, Docker Desktop, Colima, or Docker Engine on Linux).
set -euo pipefail

# HEDRONOS_* is a deprecated fallback: new name, then old name, then default.
warn_if_deprecated() {
  local new="$1" old="$2"
  if [[ -z "${!new:-}" && -n "${!old:-}" ]]; then
    printf 'hedronite-lab  warning: %s is deprecated; use %s\n' "$old" "$new" >&2
  fi
}

warn_if_deprecated HEDRONDOJO_REPO_ORG HEDRONOS_REPO_ORG
warn_if_deprecated HEDRONDOJO_REF HEDRONOS_REF
warn_if_deprecated HEDRONDOJO_HOME HEDRONOS_HOME
warn_if_deprecated HEDRONDOJO_SHARE_DIR HEDRONOS_SHARE_DIR
warn_if_deprecated HEDRONDOJO_BIN_DIR HEDRONOS_BIN_DIR
warn_if_deprecated HEDRONDOJO_PORT HEDRONOS_PORT
warn_if_deprecated HEDRONDOJO_LAB_IMAGE HEDRONOS_LAB_IMAGE
warn_if_deprecated HEDRONDOJO_LAB_ZSH_URL HEDRONOS_LAB_ZSH_URL
warn_if_deprecated HEDRONDOJO_VERSION HEDRONOS_VERSION
warn_if_deprecated HEDRONDOJO_KERNEL_IMAGE HEDRONOS_KERNEL_IMAGE
warn_if_deprecated HEDRONDOJO_KERNEL_TAG HEDRONOS_KERNEL_TAG
warn_if_deprecated HEDRONDOJO_BINARY HEDRONOS_BINARY
warn_if_deprecated HEDRONDOJO_UPDATE HEDRONOS_UPDATE
warn_if_deprecated HEDRONDOJO_NO_MODIFY_PATH HEDRONOS_NO_MODIFY_PATH
warn_if_deprecated HEDRONDOJO_NO_OBSIDIAN HEDRONOS_NO_OBSIDIAN

REPO_ORG="${HEDRONDOJO_REPO_ORG:-${HEDRONOS_REPO_ORG:-Hedronite}}"
REPO_REF="${HEDRONDOJO_REF:-${HEDRONOS_REF:-main}}"
INSTALL_ROOT="${HEDRONDOJO_HOME:-${HEDRONOS_HOME:-$HOME/.local/share/hedronite/hedrondojo}}"
SHARE_DIR="${HEDRONDOJO_SHARE_DIR:-${HEDRONOS_SHARE_DIR:-$HOME/.local/share/hedronite}}"
BIN_DIR="${HEDRONDOJO_BIN_DIR:-${HEDRONOS_BIN_DIR:-$HOME/.local/bin}}"
PORT="${HEDRONDOJO_PORT:-${HEDRONOS_PORT:-18800}}"
LAB_IMAGE="${HEDRONDOJO_LAB_IMAGE:-${HEDRONOS_LAB_IMAGE:-ghcr.io/hedronite/lab:latest}}"
LAB_ZSH_URL="${HEDRONDOJO_LAB_ZSH_URL:-${HEDRONOS_LAB_ZSH_URL:-https://raw.githubusercontent.com/VirtualMachinist/hedronite-devops-lab/main/shell/lab.zsh}}"
DO_UPDATE="${HEDRONDOJO_UPDATE:-${HEDRONOS_UPDATE:-0}}"
NO_MODIFY_PATH="${HEDRONDOJO_NO_MODIFY_PATH:-${HEDRONOS_NO_MODIFY_PATH:-0}}"
NO_OBSIDIAN="${HEDRONDOJO_NO_OBSIDIAN:-${HEDRONOS_NO_OBSIDIAN:-0}}"
VERSION_OVERRIDE="${HEDRONDOJO_VERSION:-${HEDRONOS_VERSION:-}}"
LOCAL_BINARY="${HEDRONDOJO_BINARY:-${HEDRONOS_BINARY:-}}"

say()  { printf 'hedronite-lab  %s\n' "$*"; }
fail() { printf 'hedronite-lab  %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: install.sh [--headless]

  Powers on the HedronDojo kernel (127.0.0.1:18800), installs the hedrondojo and lab
  commands into ~/.local/bin, then opens HedronDojo.

  --headless   kernel + commands only; do not open Obsidian or the TUI

Environment (all optional):
  HEDRONDOJO_VERSION        release tag for binary + kernel image (default: VERSION file)
  HEDRONDOJO_KERNEL_IMAGE   kernel image repository (default: ghcr.io/hedronite/hedrondojo-kernel)
  HEDRONDOJO_KERNEL_TAG     kernel image tag (default: HEDRONDOJO_VERSION)
  HEDRONDOJO_BINARY         use this local hedrondojo binary instead of downloading
  HEDRONDOJO_HOME           where the kernel files live (default: ~/.local/share/hedronite/hedrondojo)
  HEDRONDOJO_BIN_DIR        where hedrondojo and lab go (default: ~/.local/bin)
  HEDRONDOJO_PORT           host port for the kernel (default: 18800)
  HEDRONDOJO_REF            git ref fetched on the curl path (default: main)
  HEDRONDOJO_UPDATE=1       refresh kernel files on the curl path (vault/ is kept)
  HEDRONDOJO_NO_MODIFY_PATH=1  do not add ~/.local/bin to your shell rc

  HEDRONOS_* names still work when the matching HEDRONDOJO_* variable is unset.
  The installer prints a deprecation warning on stderr.

Contributors (build the kernel locally instead of pulling):
  docker compose -f compose.yaml -f compose.dev.yaml up --build -d
USAGE
}

HEADLESS=0
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS=1 ;;
    -h|--help) usage; exit 0 ;;
    *) usage >&2; fail "unknown flag: $arg" ;;
  esac
done

case "$(uname -s 2>/dev/null || echo unknown)" in
  Darwin) OS_NAME=Darwin ;;
  Linux) OS_NAME=Linux ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT) fail "Windows: run this inside WSL2 (Ubuntu), then re-run." ;;
  *) fail "unsupported OS: $(uname -s)" ;;
esac

for tool in curl tar; do
  command -v "$tool" >/dev/null 2>&1 || fail "need $tool on PATH"
done

# ---------------------------------------------------------------- kernel files
# Running from a checkout uses that checkout. Piped from curl, fetch the tree.
script_path="${BASH_SOURCE[0]:-}"
if [[ -n "$script_path" && -f "$script_path" && -f "$(cd "$(dirname "$script_path")" && pwd)/compose.yaml" ]]; then
  ROOT="$(cd "$(dirname "$script_path")" && pwd)"
else
  ROOT="$INSTALL_ROOT"
  if [[ ! -f "$ROOT/compose.yaml" || "$DO_UPDATE" == "1" ]]; then
    say "fetching HedronDojo ($REPO_REF)"
    tmp_tree="$(mktemp -d)"
    trap 'rm -rf "$tmp_tree"' EXIT
    curl -fsSL "https://github.com/${REPO_ORG}/hedrondojo/archive/${REPO_REF}.tar.gz" \
      | tar -xz -C "$tmp_tree" --strip-components 1 \
      || fail "could not fetch HedronDojo from github.com/${REPO_ORG}/hedrondojo"
    mkdir -p "$ROOT"
    # The vault is the student's. Never overwrite an existing one.
    [[ -d "$ROOT/vault" ]] && rm -rf "$tmp_tree/vault"
    cp -R "$tmp_tree"/. "$ROOT"/
  fi
fi
cd "$ROOT"

release_tag() {
  if [[ -n "$VERSION_OVERRIDE" ]]; then
    echo "$VERSION_OVERRIDE"
  elif [[ -s "$ROOT/VERSION" ]]; then
    tr -d '[:space:]' < "$ROOT/VERSION"
  else
    echo latest
  fi
}
TAG="$(release_tag)"

# ------------------------------------------------------------------- HedronVM
engine_ok() { command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1; }

wait_engine() {
  local i
  for ((i = 0; i < $1; i++)); do
    engine_ok && return 0
    sleep 1
  done
  return 1
}

power_on_hedronvm() {
  engine_ok && return 0
  if [[ "$OS_NAME" == Darwin ]]; then
    if [[ -d /Applications/OrbStack.app ]] || command -v orb >/dev/null 2>&1; then
      say "powering on HedronVM (OrbStack)"
      open -ga OrbStack >/dev/null 2>&1 || orb start >/dev/null 2>&1 || true
      wait_engine 90 && return 0
    fi
    if command -v colima >/dev/null 2>&1; then
      say "powering on HedronVM (Colima)"
      if [[ "$(uname -m)" == arm64 ]]; then
        colima start --arch aarch64 --vm-type=vz --vz-rosetta >/dev/null 2>&1 || colima start >/dev/null 2>&1 || true
      else
        colima start >/dev/null 2>&1 || true
      fi
      wait_engine 60 && return 0
    fi
    if [[ -d /Applications/Docker.app ]]; then
      say "powering on HedronVM (Docker Desktop)"
      open -ga Docker >/dev/null 2>&1 || true
      wait_engine 120 && return 0
    fi
    fail "HedronVM needs a runtime. Install OrbStack (https://orbstack.dev), open it once, then re-run."
  fi
  if command -v docker >/dev/null 2>&1; then
    fail "HedronVM is powered off. Start Docker Engine (sudo systemctl start docker) and make sure your user can run it, then re-run."
  fi
  fail "HedronVM needs Docker Engine + the compose plugin: https://docs.docker.com/engine/install/ — then re-run."
}

memory_floor() {
  local bytes=0
  if [[ "$OS_NAME" == Darwin ]]; then
    bytes="$(sysctl -n hw.memsize 2>/dev/null || echo 0)"
  elif [[ -r /proc/meminfo ]]; then
    bytes="$(awk '/MemTotal/ {print $2 * 1024}' /proc/meminfo)"
  fi
  if (( bytes > 0 && bytes < 7500000000 )); then
    say "note: under 8 GB RAM; HedronDojo may be slow"
  fi
}

memory_floor
power_on_hedronvm
docker compose version >/dev/null 2>&1 || fail "HedronVM runtime is missing the compose plugin; update OrbStack / Docker Desktop, or install docker-compose-plugin."

# --------------------------------------------------------------------- kernel
if [[ ! -s "$ROOT/seed/lattice.db" ]]; then
  if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$ROOT/seed/schema.sql" && -f "$ROOT/seed/seed.sql" ]]; then
    sqlite3 "$ROOT/seed/lattice.db" < "$ROOT/seed/schema.sql"
    sqlite3 "$ROOT/seed/lattice.db" < "$ROOT/seed/seed.sql"
  else
    fail "lattice seed missing: $ROOT/seed/lattice.db"
  fi
fi

export HEDRONDOJO_KERNEL_TAG="${HEDRONDOJO_KERNEL_TAG:-${HEDRONOS_KERNEL_TAG:-$TAG}}"
export HEDRONDOJO_PORT="$PORT"
export HEDRONDOJO_KERNEL_IMAGE="${HEDRONDOJO_KERNEL_IMAGE:-${HEDRONOS_KERNEL_IMAGE:-ghcr.io/hedronite/hedrondojo-kernel}}"
kernel_ref="${HEDRONDOJO_KERNEL_IMAGE}:${HEDRONDOJO_KERNEL_TAG}"

say "loading kernel $kernel_ref"
if ! docker compose up -d --quiet-pull >"$ROOT/.kernel-up.log" 2>&1; then
  cat "$ROOT/.kernel-up.log" >&2
  fail "kernel did not power on (image $kernel_ref). Log: $ROOT/.kernel-up.log"
fi

kernel_ready() { curl -fsS -m 2 "http://127.0.0.1:${PORT}/ready" 2>/dev/null | grep -Eq '"ok": ?true'; }
ready=0
for ((i = 0; i < 90; i++)); do
  if kernel_ready; then ready=1; break; fi
  sleep 1
done
(( ready )) || fail "kernel is not answering on 127.0.0.1:${PORT}/ready"
say "kernel ready on 127.0.0.1:${PORT}"

# ----------------------------------------------------------------- hedrondojo
platform_suffix() {
  case "${OS_NAME}-$(uname -m)" in
    Darwin-arm64|Darwin-aarch64) echo darwin-arm64 ;;
    Darwin-x86_64) echo darwin-amd64 ;;
    Linux-aarch64|Linux-arm64) echo linux-arm64 ;;
    Linux-x86_64) echo linux-amd64 ;;
    *) fail "no hedrondojo build for ${OS_NAME} $(uname -m)" ;;
  esac
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

install_hedrondojo() {
  local plat url tmp dest marker
  dest="$BIN_DIR/hedrondojo"
  marker="$SHARE_DIR/hedrondojo.version"
  mkdir -p "$BIN_DIR" "$SHARE_DIR"

  if [[ -n "$LOCAL_BINARY" ]]; then
    [[ -x "$LOCAL_BINARY" ]] || fail "local binary is not executable: $LOCAL_BINARY"
    cp "$LOCAL_BINARY" "$dest.tmp" && chmod +x "$dest.tmp" && mv "$dest.tmp" "$dest"
    echo "local" > "$marker"
    return 0
  fi

  if [[ -x "$dest" && "$(cat "$marker" 2>/dev/null)" == "$TAG" ]]; then
    return 0
  fi

  plat="$(platform_suffix)"
  if [[ "$TAG" == latest ]]; then
    url="https://github.com/${REPO_ORG}/hedrondojo/releases/latest/download/hedrondojo-${plat}"
  else
    url="https://github.com/${REPO_ORG}/hedrondojo/releases/download/${TAG}/hedrondojo-${plat}"
  fi

  say "installing hedrondojo $TAG ($plat)"
  tmp="$(mktemp)"
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    fail "could not download hedrondojo $TAG for $plat. Releases: https://github.com/${REPO_ORG}/hedrondojo/releases"
  fi
  if curl -fsSL "$url.sha256" -o "$tmp.sha256" 2>/dev/null; then
    if [[ "$(awk '{print $1}' "$tmp.sha256")" != "$(sha256_of "$tmp")" ]]; then
      rm -f "$tmp" "$tmp.sha256"
      fail "hedrondojo download failed its checksum; re-run to retry"
    fi
  fi
  rm -f "$tmp.sha256"
  chmod +x "$tmp"
  mv "$tmp" "$dest"
  [[ "$OS_NAME" == Darwin ]] && xattr -d com.apple.quarantine "$dest" >/dev/null 2>&1 || true
  echo "$TAG" > "$marker"
}

install_command_shim() {
  # scripts/hedronos warns on stderr and execs the sibling hedrondojo.
  cp "$ROOT/scripts/hedronos" "$BIN_DIR/hedronos"
  chmod +x "$BIN_DIR/hedronos"
}

# ------------------------------------------------------------------------ lab
install_lab() {
  local zsh_file="$SHARE_DIR/lab.zsh"
  mkdir -p "$SHARE_DIR" "$BIN_DIR"
  if ! curl -fsSL "$LAB_ZSH_URL" -o "$zsh_file.tmp"; then
    rm -f "$zsh_file.tmp"
    say "lab toolbox shell layer unavailable right now; re-run later for the lab command"
    return 0
  fi
  mv "$zsh_file.tmp" "$zsh_file"

  cat > "$BIN_DIR/lab" <<SHIM
#!/bin/sh
# hedronite-lab: the lab verb. Logic lives in lab.zsh (VirtualMachinist/hedronite-devops-lab).
LAB_ZSH="\${HEDRONITE_LAB_ZSH:-$zsh_file}"
: "\${LAB_IMAGE:=$LAB_IMAGE}"
export LAB_IMAGE
if ! command -v zsh >/dev/null 2>&1; then
  echo "lab needs zsh (Debian/Ubuntu: sudo apt install zsh)" >&2
  exit 127
fi
exec zsh -c 'source "\$1" || exit 1; shift; lab "\$@"' lab "\$LAB_ZSH" "\$@"
SHIM
  chmod +x "$BIN_DIR/lab"

  # Warm the toolbox image so the first `lab` does not wait on a cold pull.
  nohup docker pull "$LAB_IMAGE" >"$SHARE_DIR/lab-pull.log" 2>&1 </dev/null &
  say "warming the lab toolbox in the background (log: $SHARE_DIR/lab-pull.log)"
}

ensure_path() {
  case ":$PATH:" in *":$BIN_DIR:"*) return 0 ;; esac
  [[ "$NO_MODIFY_PATH" == "1" ]] && return 0
  local line rc
  line="export PATH=\"$BIN_DIR:\$PATH\"  # hedronite-lab"
  case "$(basename "${SHELL:-sh}")" in
    zsh) rc="$HOME/.zshrc" ;;
    bash) if [[ "$OS_NAME" == Darwin ]]; then rc="$HOME/.bash_profile"; else rc="$HOME/.bashrc"; fi ;;
    *) rc="$HOME/.profile" ;;
  esac
  if ! grep -qF "# hedronite-lab" "$rc" 2>/dev/null; then
    printf '\n%s\n' "$line" >> "$rc"
  fi
  say "added $BIN_DIR to PATH in $rc (new terminals pick it up)"
}

install_hedrondojo
install_command_shim
install_lab
ensure_path

# ---------------------------------------------------------------------- open
say "notes vault: $ROOT/vault"
say "re-open: hedrondojo     toolbox: lab echo ok"

if (( HEADLESS )); then
  exit 0
fi

if [[ "$OS_NAME" == Darwin && -d /Applications/Obsidian.app && "$NO_OBSIDIAN" != "1" ]]; then
  open -ga Obsidian "$ROOT/vault" >/dev/null 2>&1 || true
fi

if [[ "$PORT" != 18800 ]]; then
  export HEDRON_KERNEL="http://127.0.0.1:${PORT}"
fi

# curl | bash leaves stdin on the pipe; hand the TUI the real terminal.
if [[ -t 1 ]] && (exec </dev/tty) 2>/dev/null; then
  exec "$BIN_DIR/hedrondojo" </dev/tty
fi
say "no terminal attached; run hedrondojo to open HedronDojo"
