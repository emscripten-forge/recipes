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

log "Initial environment (before sanitizing flags)"
printenv | grep -E 'CFLAGS|CXXFLAGS|FCFLAGS|march|mtune' || true

strip_cpu_flags() {
  echo "$1" \
    | sed -E 's/-march=[^ ]+//g' \
    | sed -E 's/-mtune=[^ ]+//g' \
    | sed -E 's/-fno-plt//g'
}

WRAPPER="${RECIPE_DIR}/empp-wrapper.sh"
WASM_LD_WRAPPER="${RECIPE_DIR}/wasm-ld-wrapper.sh"

chmod +x "$WRAPPER"
chmod +x "$WASM_LD_WRAPPER"

export CXX="$WRAPPER"
export CXXFLAGS=""
echo "Using CXX=$CXX"
ls -l "$CXX"

export WASM_LD="$WASM_LD_WRAPPER"

export FCFLAGS="$(strip_cpu_flags "${FCFLAGS:-}")"

log "Sanitized flags"
echo "CFLAGS   = ${CFLAGS:-<unset>}"
echo "CXXFLAGS = ${CXXFLAGS:-<unset>}"
echo "FCFLAGS  = ${FCFLAGS:-<unset>}"

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
