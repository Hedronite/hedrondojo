#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$ROOT"

HEADLESS=0
for arg in "$@"; do
  case "$arg" in
    --headless) HEADLESS=1 ;;
    -h|--help)
      echo "Usage: ./install.sh [--headless]"
      echo "  --headless  skip Obsidian and the HedronOS TUI"
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

if docker_engine_ok; then
  :
elif command -v colima >/dev/null 2>&1; then
  colima start
  if ! docker_engine_ok; then
    echo "container runtime is not ready"
    exit 1
  fi
elif command -v docker >/dev/null 2>&1; then
  echo "Docker is installed but the engine is not running. Start it, then re-run."
  exit 1
else
  echo "Need Docker or Colima. Install one, then re-run."
  exit 1
fi

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

docker compose up -d

wait_ready() {
  local i
  for i in $(seq 1 30); do
    if python3 -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:18800/ready', timeout=2)" >/dev/null 2>&1; then
      return 0
    fi
    sleep 1
  done
  echo "kernel not ready on 127.0.0.1:18800" >&2
  return 1
}
wait_ready

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

if [[ "$HEADLESS" -eq 0 ]]; then
  BIN=""
  if command -v hedronos >/dev/null 2>&1; then
    BIN="$(command -v hedronos)"
  elif [[ -x "$ROOT/crates/hedronos/target/release/hedronos" ]]; then
    BIN="$ROOT/crates/hedronos/target/release/hedronos"
  elif [[ -x "$ROOT/crates/hedronos/target/debug/hedronos" ]]; then
    BIN="$ROOT/crates/hedronos/target/debug/hedronos"
  fi
  if [[ -n "$BIN" ]]; then
    exec "$BIN"
  fi
  echo "HedronOS is not built yet. cargo build --manifest-path crates/hedronos/Cargo.toml"
  echo "Then run hedronos, or re-run ./install.sh"
fi
