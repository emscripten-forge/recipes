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

rm $BUILD_PREFIX/bin/wasm-ld

WRAPPER="${RECIPE_DIR}/empp-wrapper.sh"

chmod +x "$WRAPPER"

export CXX="$WRAPPER"
export CXXFLAGS=""
echo "Using CXX=$CXX"
ls -l "$CXX"

cp "${RECIPE_DIR}/wasm-ld-wrapper.sh" "$BUILD_PREFIX/bin/wasm-ld"
chmod +x "$BUILD_PREFIX/bin/wasm-ld"


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

log "Installing package into PREFIX"
octave -W -H --eval "
pkg prefix '${PREFIX}/share/octave/packages' '${PREFIX}/octave/packages';
pkg install -nodeps ${BUILD_DIR}/*.tar.gz;
pkg list;
"

log "Verify installation"
find "${PREFIX}" -maxdepth 5 -print


log "PWD after build"
pwd

log "Contents of PWD"
ls -lah || true

log "Recursive tree (depth 3)"
find . -maxdepth 3 -type d -print || true

log "Contents of BUILD_DIR"
ls -lah "$BUILD_DIR" || true

log "Recursive BUILD_DIR"
find "$BUILD_DIR" -maxdepth 5 || true

log "Check SRC_DIR"
echo "SRC_DIR=${SRC_DIR:-<unset>}"
if [[ -n "${SRC_DIR:-}" && -d "${SRC_DIR}" ]]; then
  ls -lah "${SRC_DIR}" || true
  find "${SRC_DIR}" -maxdepth 5 -type d -name "image*" || true
fi

log "Check BUILD_PREFIX"
echo "BUILD_PREFIX=${BUILD_PREFIX:-<unset>}"
if [[ -n "${BUILD_PREFIX:-}" && -d "${BUILD_PREFIX}" ]]; then
  ls -lah "${BUILD_PREFIX}" || true
fi

log "Searching for package directories"
find . -type d -name "image*" || true

log "Searching for .oct files"
find . -type f -name "*.oct" || true

log "Searching for config.log"
find . -type f -name "config.log" || true

log "END DEBUG"

log "Inspecting produced binary package"

mkdir -p inspect_pkg
tar -xzf _builddir/*.tar.gz -C inspect_pkg

find inspect_pkg -maxdepth 5 -print



# CONFIG_LOG="${BUILD_DIR}/${PKG}/src/config.log"

# if [[ -f "${CONFIG_LOG}" ]]; then
#   echo "===== config.log ====="
#   cat "${CONFIG_LOG}"
#   echo "===== end config.log ====="

#   cp "${CONFIG_LOG}" "${LOG_DIR}/config.log"
# else
#   echo "config.log not found at ${CONFIG_LOG}"
#   echo "Build directory contents:"
#   find "${BUILD_DIR}" -maxdepth 4 || true
#   exit 1
# fi
