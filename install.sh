#!/usr/bin/env bash
set -euo pipefail

REPO_ORG="${HEDRONOS_REPO_ORG:-VirtualMachinist}"
INSTALL_ROOT="${HEDRONOS_HOME:-${HOME}/.local/share/hedronite/hedronos}"
if [[ -n "${BASH_SOURCE[0]:-}" && "${BASH_SOURCE[0]}" != "bash" && -f "$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/compose.yaml" ]]; then
  ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
else
  ROOT="$INSTALL_ROOT"
  if [[ ! -f "$ROOT/compose.yaml" ]]; then
    if command -v git >/dev/null 2>&1; then
      rm -rf "$ROOT"
      git clone --depth 1 "https://github.com/${REPO_ORG}/hedronos.git" "$ROOT"
    else
      echo "need git to install HedronOS (or clone the repo and run ./install.sh)" >&2
      exit 1
    fi
  fi
fi
cd "$ROOT"

KERNEL_IMAGE="${HEDRONOS_KERNEL_IMAGE:-ghcr.io/hedronite/hedronos-kernel}"
LAB_IMAGE="${HEDRONOS_LAB_IMAGE:-ghcr.io/hedronite/lab:latest}"
LAB_ZSH_URL="${HEDRONOS_LAB_ZSH_URL:-https://raw.githubusercontent.com/${REPO_ORG}/hedronite-devops-lab/main/shell/lab.zsh}"
BIN_DIR="${HEDRONOS_BIN_DIR:-${HOME}/.local/bin}"
SHARE_DIR="${HEDRONOS_SHARE_DIR:-${HOME}/.local/share/hedronite}"

HEADLESS=0
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS=1 ;;
    -h|--help)
      cat <<'EOF'
Usage: ./install.sh [--headless]

  Brings up the HedronOS kernel, installs the hedronos binary and lab() shell
  function, then launches the TUI (unless --headless).

  Environment overrides:
    HEDRONOS_VERSION          release tag (default: VERSION file or latest)
    HEDRONOS_KERNEL_TAG       kernel image tag (default: VERSION file or latest)
    HEDRONOS_BIN_DIR          install dir for hedronos (default: ~/.local/bin)
EOF
      exit 0
      ;;
    *)
      echo "unknown flag: $arg" >&2
      echo "Usage: ./install.sh [--headless]" >&2
      exit 1
      ;;
  esac
done

uname_s="$(uname -s 2>/dev/null || echo unknown)"
case "$uname_s" in
  Darwin) OS_NAME=Darwin ;;
  Linux) OS_NAME=Linux ;;
  MINGW*|MSYS*|CYGWIN*|Windows_NT) OS_NAME=Windows ;;
  *)
    echo "unsupported OS: $uname_s"
    exit 1
    ;;
esac

docker_engine_ok() {
  command -v docker >/dev/null 2>&1 && docker info >/dev/null 2>&1
}

orbstack_present() {
  [[ -d "/Applications/OrbStack.app" ]] || command -v orb >/dev/null 2>&1
}

start_colima() {
  if [[ "$(uname -m 2>/dev/null || echo unknown)" == "arm64" ]]; then
    colima start --arch aarch64 --vm-type=vz --vz-rosetta 2>/dev/null || colima start
  else
    colima start
  fi
}

ensure_docker() {
  if docker_engine_ok; then
    return 0
  fi
  if orbstack_present; then
    echo "OrbStack is installed but Docker is not running. Open OrbStack, then re-run."
    exit 1
  fi
  if command -v colima >/dev/null 2>&1; then
    start_colima
    if docker_engine_ok; then
      return 0
    fi
    echo "container runtime is not ready"
    exit 1
  fi
  if command -v docker >/dev/null 2>&1; then
    echo "Docker is installed but the engine is not running. Start it, then re-run."
    exit 1
  fi
  if [[ "$OS_NAME" == Darwin ]]; then
    echo "Need OrbStack or Colima on macOS. Install one, then re-run."
  else
    echo "Need Docker Engine. Install it, then re-run."
  fi
  exit 1
}

platform_suffix() {
  local arch
  arch="$(uname -m 2>/dev/null || echo unknown)"
  case "${OS_NAME}-${arch}" in
    Darwin-arm64|Darwin-aarch64) echo "darwin-arm64" ;;
    Darwin-x86_64) echo "darwin-amd64" ;;
    Linux-aarch64|Linux-arm64) echo "linux-arm64" ;;
    Linux-x86_64) echo "linux-amd64" ;;
    *)
      echo "unsupported platform: ${OS_NAME} ${arch}" >&2
      return 1
      ;;
  esac
}

release_tag() {
  if [[ -n "${HEDRONOS_VERSION:-}" ]]; then
    echo "$HEDRONOS_VERSION"
    return 0
  fi
  if [[ -f "$ROOT/VERSION" ]]; then
    tr -d '[:space:]' < "$ROOT/VERSION"
    return 0
  fi
  echo "latest"
}

install_hedronos_binary() {
  local plat tag url dest
  plat="$(platform_suffix)"
  tag="$(release_tag)"
  dest="$BIN_DIR/hedronos"
  mkdir -p "$BIN_DIR"

  if [[ -x "$dest" ]] && [[ "${HEDRONOS_REINSTALL_BINARY:-0}" != "1" ]]; then
    return 0
  fi

  if [[ "$tag" == "latest" ]]; then
    url="https://github.com/${REPO_ORG}/hedronos/releases/latest/download/hedronos-${plat}"
  else
    url="https://github.com/${REPO_ORG}/hedronos/releases/download/${tag}/hedronos-${plat}"
  fi

  if ! curl -fsSL "$url" -o "$dest"; then
    echo "could not fetch hedronos binary (${plat}). See https://github.com/${REPO_ORG}/hedronos/releases" >&2
    exit 1
  fi
  chmod +x "$dest"
}

install_lab_shell() {
  local dest="$SHARE_DIR/lab.zsh"
  mkdir -p "$SHARE_DIR"
  curl -fsSL "$LAB_ZSH_URL" -o "$dest"

  if [[ -n "${ZSH_VERSION:-}" ]]; then
    # shellcheck disable=SC1090
    source "$dest"
  fi

  if [[ -f "${HOME}/.zshrc" ]] && ! grep -q 'hedronite/lab.zsh' "${HOME}/.zshrc" 2>/dev/null; then
    cat >> "${HOME}/.zshrc" <<EOF

# hedronite-lab toolbox (optional; override with HEDRONOS_LAB_ZSH_URL)
[[ -r "${dest}" ]] && source "${dest}"
EOF
  fi
}

ensure_docker

# Never delete seed/lattice.db. Build the template first so compose can copy it.
if [[ ! -s "$ROOT/seed/lattice.db" ]]; then
  if command -v sqlite3 >/dev/null 2>&1 && [[ -f "$ROOT/seed/schema.sql" && -f "$ROOT/seed/seed.sql" ]]; then
    sqlite3 "$ROOT/seed/lattice.db" < "$ROOT/seed/schema.sql"
    sqlite3 "$ROOT/seed/lattice.db" < "$ROOT/seed/seed.sql"
  else
    echo "lattice seed missing" >&2
    exit 1
  fi
fi

export HEDRONOS_KERNEL_TAG="${HEDRONOS_KERNEL_TAG:-$(release_tag)}"

if ! docker compose pull; then
  echo "could not pull ${KERNEL_IMAGE}:${HEDRONOS_KERNEL_TAG}" >&2
  echo "Contributors: docker compose -f compose.yaml -f compose.dev.yaml up --build -d" >&2
  exit 1
fi
docker compose up -d

docker pull "$LAB_IMAGE" >/dev/null 2>&1 || true

wait_ready() {
  local i
  for i in $(seq 1 60); do
    if python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:18800/ready', timeout=2)" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "kernel not ready on 127.0.0.1:18800" >&2
  return 1
}
wait_ready

install_hedronos_binary
install_lab_shell

if [[ "$HEADLESS" -eq 0 ]]; then
  if [[ "$OS_NAME" == Darwin ]]; then
    if [[ ! -d "/Applications/Obsidian.app" ]]; then
      if command -v brew >/dev/null 2>&1; then
        brew install --cask obsidian
      else
        echo "Obsidian: https://obsidian.md"
      fi
    fi
    if [[ -d "/Applications/Obsidian.app" ]]; then
      open -a Obsidian "$ROOT/vault"
    fi
  else
    echo "Obsidian: https://obsidian.md"
  fi
fi

echo "PDF checklist path: checklists/tomes.md"
echo "Lessons feed: https://hedronite.com"
echo "Bot attach: In Grok Bot / Cursor / Cowork: open this folder, then run @hedronite-lab"
echo "DevOps toolbox: lab (ghcr.io/hedronite/lab)"

if [[ "$HEADLESS" -eq 0 ]]; then
  BIN=""
  if [[ -x "$BIN_DIR/hedronos" ]]; then
    BIN="$BIN_DIR/hedronos"
  elif command -v hedronos >/dev/null 2>&1; then
    BIN="$(command -v hedronos)"
  elif [[ -x "$ROOT/crates/hedronos/target/release/hedronos" ]]; then
    BIN="$ROOT/crates/hedronos/target/release/hedronos"
  elif [[ -x "$ROOT/crates/hedronos/target/debug/hedronos" ]]; then
    BIN="$ROOT/crates/hedronos/target/debug/hedronos"
  fi
  if [[ -n "$BIN" ]]; then
    export PATH="$BIN_DIR:$PATH"
    exec "$BIN"
  fi
  echo "hedronos binary missing after install — check https://github.com/${REPO_ORG}/hedronos/releases" >&2
  exit 1
fi
