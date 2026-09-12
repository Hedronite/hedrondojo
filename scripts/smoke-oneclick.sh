#!/usr/bin/env bash
# Timed stranger DoD for hedronite-lab (SoT plan 2026-09-12 §3).
#
# Runs install.sh the way a stranger does (piped to bash, fresh HOME), then checks:
#   1. GET /ready -> ok:true
#   2. hedronos reaches Boot -> Home (hedronos --smoke)
#   3. lab echo ok
#   4. re-open: hedronos again, kernel still up
# and prints wall-clock against the 10-minute budget.
#
#   scripts/smoke-oneclick.sh                    # install.sh from main on GitHub
#   INSTALL_SH=./install.sh HEDRONOS_REF=my-branch scripts/smoke-oneclick.sh
#
# Your real HOME, rc files, and credentials are not touched: the run uses a
# throwaway HOME. Leaves the kernel running; `docker compose -p hedronos down -v` stops it.
set -euo pipefail

BUDGET=600
PORT="${HEDRONOS_PORT:-18800}"
REF="${HEDRONOS_REF:-main}"
INSTALL_SH="${INSTALL_SH:-https://raw.githubusercontent.com/VirtualMachinist/hedronos/${REF}/install.sh}"

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/hedronite-lab-smoke.XXXXXX")"
export DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
export HOME="$sandbox/home"
export SHELL=/bin/zsh
export PATH="$HOME/.local/bin:$PATH"
export HEDRONOS_PORT="$PORT" HEDRONOS_REF="$REF"
export HEDRON_KERNEL="http://127.0.0.1:${PORT}"
mkdir -p "$HOME"

log() { printf '[%4ss] %s\n' "$(( $(date +%s) - t0 ))" "$*"; }
t0="$(date +%s)"
fails=0
check() {
  local name="$1"; shift
  if "$@"; then log "PASS $name"; else log "FAIL $name"; fails=$((fails + 1)); fi
}

log "sandbox HOME $HOME"
if [[ "$INSTALL_SH" == http* ]]; then
  curl -fsSL "$INSTALL_SH" | bash -s -- --headless
else
  bash -s -- --headless < "$INSTALL_SH"
fi
log "install.sh returned"

ready() { curl -fsS -m 3 "http://127.0.0.1:${PORT}/ready" | tee "$sandbox/ready.json" | grep -Eq '"ok": ?true'; }
boot_home() { hedronos --smoke; }
lab_ok() { [[ "$(lab echo ok 2>/dev/null | tail -n1 | tr -d '\r')" == ok ]]; }

check "ready" ready
log "ready body $(cat "$sandbox/ready.json" 2>/dev/null)"
check "hedronos Boot->Home" boot_home
log "waiting on lab toolbox (first pull may dominate)"
check "lab echo ok" lab_ok
check "re-open hedronos" boot_home
check "kernel still up" ready

elapsed=$(( $(date +%s) - t0 ))
if (( elapsed > BUDGET )); then
  log "FAIL wall clock ${elapsed}s > ${BUDGET}s"
  fails=$((fails + 1))
else
  log "PASS wall clock ${elapsed}s <= ${BUDGET}s"
fi
log "binary: $(command -v hedronos)  lab: $(command -v lab)"
exit "$fails"
