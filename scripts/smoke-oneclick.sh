#!/usr/bin/env bash
# Timed stranger DoD for hedronite-lab (SoT plan 2026-09-12 §3).
#
# Runs install.sh the way a stranger does (piped to bash, fresh HOME), then checks:
#   1. GET /ready -> ok:true
#   2. hedrondojo reaches Boot -> Home (hedrondojo --smoke)
#   3. lab echo ok
#   4. re-open: hedrondojo again, kernel still up
#   5. the hedronos shim warns on stderr and still reaches Home
# and prints wall-clock against the 10-minute budget.
#
#   scripts/smoke-oneclick.sh                    # install.sh from main on GitHub
#   INSTALL_SH=./install.sh HEDRONDOJO_REF=my-branch scripts/smoke-oneclick.sh
#
# Your real HOME, rc files, and credentials are not touched: the run uses a
# throwaway HOME. Leaves the kernel running; `docker compose -p hedrondojo down -v` stops it.
#
# HEDRONOS_PORT and HEDRONOS_REF still work when the HEDRONDOJO_* name is unset.
set -euo pipefail

BUDGET=600
if [[ -z "${HEDRONDOJO_PORT:-}" && -n "${HEDRONOS_PORT:-}" ]]; then
  printf 'warning: HEDRONOS_PORT is deprecated; use HEDRONDOJO_PORT\n' >&2
fi
if [[ -z "${HEDRONDOJO_REF:-}" && -n "${HEDRONOS_REF:-}" ]]; then
  printf 'warning: HEDRONOS_REF is deprecated; use HEDRONDOJO_REF\n' >&2
fi
PORT="${HEDRONDOJO_PORT:-${HEDRONOS_PORT:-18800}}"
REF="${HEDRONDOJO_REF:-${HEDRONOS_REF:-main}}"
INSTALL_SH="${INSTALL_SH:-https://raw.githubusercontent.com/Hedronite/hedrondojo/${REF}/install.sh}"

sandbox="$(mktemp -d "${TMPDIR:-/tmp}/hedronite-lab-smoke.XXXXXX")"
export DOCKER_CONFIG="${DOCKER_CONFIG:-$HOME/.docker}"
export HOME="$sandbox/home"
export SHELL=/bin/zsh
export PATH="$HOME/.local/bin:$PATH"
export HEDRONDOJO_PORT="$PORT" HEDRONDOJO_REF="$REF"
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
boot_home() { hedrondojo --smoke; }
lab_ok() { [[ "$(lab echo ok 2>/dev/null | tail -n1 | tr -d '\r')" == ok ]]; }
# scripts/hedronos: deprecation warning on stderr, then the real binary.
shim_forwards() {
  local err rc
  err="$(hedronos --smoke 2>&1 >/dev/null)"
  rc=$?
  [[ $rc -eq 0 ]] && printf '%s\n' "$err" | grep -q 'deprecated'
}

check "ready" ready
log "ready body $(cat "$sandbox/ready.json" 2>/dev/null)"
check "hedrondojo Boot->Home" boot_home
log "waiting on lab toolbox (first pull may dominate)"
check "lab echo ok" lab_ok
check "re-open hedrondojo" boot_home
check "hedronos shim" shim_forwards
check "kernel still up" ready

elapsed=$(( $(date +%s) - t0 ))
if (( elapsed > BUDGET )); then
  log "FAIL wall clock ${elapsed}s > ${BUDGET}s"
  fails=$((fails + 1))
else
  log "PASS wall clock ${elapsed}s <= ${BUDGET}s"
fi
log "binary: $(command -v hedrondojo)  shim: $(command -v hedronos)  lab: $(command -v lab)"
exit "$fails"
