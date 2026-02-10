#!/usr/bin/env bash
set -euxo pipefail

PKG=image
VER=2.18.1
BUILD_DIR="_builddir"

LOG_DIR="${SRC_DIR:-$PWD}/config-logs"
mkdir -p "${LOG_DIR}"

log() {
  echo
  echo "==== $* ===="
}

strip_cpu_flags() {
  echo "$1" \
    | sed -E 's/-march=[^ ]+//g' \
    | sed -E 's/-mtune=[^ ]+//g' \
    | sed -E 's/-fno-plt//g'
}

log "mkoctfile defaults (before override)"
mkoctfile -p CFLAGS   || true
mkoctfile -p CXXFLAGS || true
mkoctfile -p LDFLAGS  || true

log "Initial environment (before sanitizing)"
printenv | grep -E '^(ALL_)?(CFLAGS|CXXFLAGS|FCFLAGS|LDFLAGS)=' || true

# ---- sanitize user flags ----
export CFLAGS="$(strip_cpu_flags "${CFLAGS:-}")"
export CXXFLAGS="$(strip_cpu_flags "${CXXFLAGS:-}")"
export FCFLAGS="$(strip_cpu_flags "${FCFLAGS:-}")"
export LDFLAGS="$(strip_cpu_flags "${LDFLAGS:-}")"

# ---- sanitize Octave-injected flags ----
export ALL_CFLAGS="$(strip_cpu_flags "$(mkoctfile -p CFLAGS)")"
export ALL_CXXFLAGS="$(strip_cpu_flags "$(mkoctfile -p CXXFLAGS)")"
export ALL_LDFLAGS="$(strip_cpu_flags "$(mkoctfile -p LDFLAGS)")"

log "Sanitized flags (effective)"
echo "ALL_CFLAGS   = ${ALL_CFLAGS}"
echo "ALL_CXXFLAGS = ${ALL_CXXFLAGS}"
echo "ALL_LDFLAGS  = ${ALL_LDFLAGS}"
echo "CFLAGS       = ${CFLAGS:-<unset>}"
echo "CXXFLAGS     = ${CXXFLAGS:-<unset>}"
echo "FCFLAGS      = ${FCFLAGS:-<unset>}"
echo "LDFLAGS      = ${LDFLAGS:-<unset>}"

log "Creating Octave package tarball"
tar -czf "${PKG}-${VER}.tar.gz" "${PKG}"
ls -lah "${PKG}-${VER}.tar.gz"

log "Running pkg build (no install, keep build dir)"
octave -W -H --eval "pkg build ${BUILD_DIR} ${PKG}-${VER}.tar.gz -verbose" || true




CONFIG_LOG="${BUILD_DIR}/${PKG}/src/config.log"

if [[ -f "${CONFIG_LOG}" ]]; then
  echo "===== config.log ====="
  cat "${CONFIG_LOG}"
  echo "===== end config.log ====="

  cp "${CONFIG_LOG}" "${LOG_DIR}/config.log"
else
  echo "config.log not found at ${CONFIG_LOG}"
  echo "Build directory contents:"
  find "${BUILD_DIR}" -maxdepth 4 || true
  exit 1
fi
