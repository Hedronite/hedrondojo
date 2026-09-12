#!/usr/bin/env bash
# hedronite-lab installer — HedronOS (kernel + TUI) and the lab toolbox.
#
#   curl -fsSL https://raw.githubusercontent.com/VirtualMachinist/hedronos/main/install.sh | bash
#
# Stranger path: no git, no cargo, no python on the host. Needs curl, tar, and a
# container runtime (OrbStack, Docker Desktop, Colima, or Docker Engine on Linux).
set -euo pipefail

REPO_ORG="${HEDRONOS_REPO_ORG:-VirtualMachinist}"
REPO_REF="${HEDRONOS_REF:-main}"
INSTALL_ROOT="${HEDRONOS_HOME:-$HOME/.local/share/hedronite/hedronos}"
SHARE_DIR="${HEDRONOS_SHARE_DIR:-$HOME/.local/share/hedronite}"
BIN_DIR="${HEDRONOS_BIN_DIR:-$HOME/.local/bin}"
PORT="${HEDRONOS_PORT:-18800}"
LAB_IMAGE="${HEDRONOS_LAB_IMAGE:-ghcr.io/hedronite/lab:latest}"
LAB_ZSH_URL="${HEDRONOS_LAB_ZSH_URL:-https://raw.githubusercontent.com/${REPO_ORG}/hedronite-devops-lab/main/shell/lab.zsh}"

say()  { printf 'hedronite-lab  %s\n' "$*"; }
fail() { printf 'hedronite-lab  %s\n' "$*" >&2; exit 1; }

usage() {
  cat <<'USAGE'
Usage: install.sh [--headless]

  Powers on the HedronOS kernel (127.0.0.1:18800), installs the hedronos and lab
  commands into ~/.local/bin, then opens HedronOS.

  --headless   kernel + commands only; do not open Obsidian or the TUI

Environment (all optional):
  HEDRONOS_VERSION        release tag for binary + kernel image (default: VERSION file)
  HEDRONOS_KERNEL_IMAGE   kernel image repository (default: ghcr.io/hedronite/hedronos-kernel)
  HEDRONOS_KERNEL_TAG     kernel image tag (default: HEDRONOS_VERSION)
  HEDRONOS_BINARY         use this local hedronos binary instead of downloading
  HEDRONOS_HOME           where the kernel files live (default: ~/.local/share/hedronite/hedronos)
  HEDRONOS_BIN_DIR        where hedronos and lab go (default: ~/.local/bin)
  HEDRONOS_PORT           host port for the kernel (default: 18800)
  HEDRONOS_REF            git ref fetched on the curl path (default: main)
  HEDRONOS_UPDATE=1       refresh kernel files on the curl path (vault/ is kept)
  HEDRONOS_NO_MODIFY_PATH=1  do not add ~/.local/bin to your shell rc

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
  if [[ ! -f "$ROOT/compose.yaml" || "${HEDRONOS_UPDATE:-0}" == "1" ]]; then
    say "fetching HedronOS ($REPO_REF)"
    tmp_tree="$(mktemp -d)"
    trap 'rm -rf "$tmp_tree"' EXIT
    curl -fsSL "https://github.com/${REPO_ORG}/hedronos/archive/${REPO_REF}.tar.gz" \
      | tar -xz -C "$tmp_tree" --strip-components 1 \
      || fail "could not fetch HedronOS from github.com/${REPO_ORG}/hedronos"
    mkdir -p "$ROOT"
    # The vault is the student's. Never overwrite an existing one.
    [[ -d "$ROOT/vault" ]] && rm -rf "$tmp_tree/vault"
    cp -R "$tmp_tree"/. "$ROOT"/
  fi
fi
cd "$ROOT"

release_tag() {
  if [[ -n "${HEDRONOS_VERSION:-}" ]]; then
    echo "$HEDRONOS_VERSION"
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
    say "note: under 8 GB RAM; HedronOS may be slow"
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

export HEDRONOS_KERNEL_TAG="${HEDRONOS_KERNEL_TAG:-$TAG}"
export HEDRONOS_PORT="$PORT"
kernel_ref="${HEDRONOS_KERNEL_IMAGE:-ghcr.io/hedronite/hedronos-kernel}:${HEDRONOS_KERNEL_TAG}"

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

# ------------------------------------------------------------------- hedronos
platform_suffix() {
  case "${OS_NAME}-$(uname -m)" in
    Darwin-arm64|Darwin-aarch64) echo darwin-arm64 ;;
    Darwin-x86_64) echo darwin-amd64 ;;
    Linux-aarch64|Linux-arm64) echo linux-arm64 ;;
    Linux-x86_64) echo linux-amd64 ;;
    *) fail "no hedronos build for ${OS_NAME} $(uname -m)" ;;
  esac
}

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  else shasum -a 256 "$1" | awk '{print $1}'; fi
}

install_hedronos() {
  local plat url tmp dest marker
  dest="$BIN_DIR/hedronos"
  marker="$SHARE_DIR/hedronos.version"
  mkdir -p "$BIN_DIR" "$SHARE_DIR"

  if [[ -n "${HEDRONOS_BINARY:-}" ]]; then
    [[ -x "$HEDRONOS_BINARY" ]] || fail "HEDRONOS_BINARY is not executable: $HEDRONOS_BINARY"
    cp "$HEDRONOS_BINARY" "$dest.tmp" && chmod +x "$dest.tmp" && mv "$dest.tmp" "$dest"
    echo "local" > "$marker"
    return 0
  fi

  if [[ -x "$dest" && "$(cat "$marker" 2>/dev/null)" == "$TAG" ]]; then
    return 0
  fi

  plat="$(platform_suffix)"
  if [[ "$TAG" == latest ]]; then
    url="https://github.com/${REPO_ORG}/hedronos/releases/latest/download/hedronos-${plat}"
  else
    url="https://github.com/${REPO_ORG}/hedronos/releases/download/${TAG}/hedronos-${plat}"
  fi

  say "installing hedronos $TAG ($plat)"
  tmp="$(mktemp)"
  if ! curl -fsSL "$url" -o "$tmp"; then
    rm -f "$tmp"
    fail "could not download hedronos $TAG for $plat. Releases: https://github.com/${REPO_ORG}/hedronos/releases"
  fi
  if curl -fsSL "$url.sha256" -o "$tmp.sha256" 2>/dev/null; then
    if [[ "$(awk '{print $1}' "$tmp.sha256")" != "$(sha256_of "$tmp")" ]]; then
      rm -f "$tmp" "$tmp.sha256"
      fail "hedronos download failed its checksum; re-run to retry"
    fi
  fi
  rm -f "$tmp.sha256"
  chmod +x "$tmp"
  mv "$tmp" "$dest"
  [[ "$OS_NAME" == Darwin ]] && xattr -d com.apple.quarantine "$dest" >/dev/null 2>&1 || true
  echo "$TAG" > "$marker"
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
  [[ "${HEDRONOS_NO_MODIFY_PATH:-0}" == "1" ]] && return 0
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

install_hedronos
install_lab
ensure_path

# ---------------------------------------------------------------------- open
say "notes vault: $ROOT/vault"
say "re-open: hedronos     toolbox: lab echo ok"

if (( HEADLESS )); then
  exit 0
fi

if [[ "$OS_NAME" == Darwin && -d /Applications/Obsidian.app && "${HEDRONOS_NO_OBSIDIAN:-0}" != "1" ]]; then
  open -ga Obsidian "$ROOT/vault" >/dev/null 2>&1 || true
fi

if [[ "$PORT" != 18800 ]]; then
  export HEDRON_KERNEL="http://127.0.0.1:${PORT}"
fi

# curl | bash leaves stdin on the pipe; hand the TUI the real terminal.
if [[ -t 1 ]] && (exec </dev/tty) 2>/dev/null; then
  exec "$BIN_DIR/hedronos" </dev/tty
fi
say "no terminal attached; run hedronos to open HedronOS"
