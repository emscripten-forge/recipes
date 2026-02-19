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

export OCTAVE_HOME=$PREFIX
export OCTAVE_EXEC_HOME=$BUILD_PREFIX


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
# echo "OCTAVE USED:"
# which octave
# echo "PREFIX = $PREFIX"
# ls -lah "$PREFIX"
# ls -lah "$PREFIX/bin"

# echo "BUILD_PREFIX = $BUILD_PREFIX"
# ls -lah "$BUILD_PREFIX"
# ls -lah "$BUILD_PREFIX/bin"

octave -W -H --eval "
pkg prefix '${PREFIX}/share/octave/packages' '${PREFIX}/lib/octave/packages';
pkg install -nodeps ${BUILD_DIR}/*.tar.gz;
pkg list;
"

mv ${PREFIX}/lib/octave/packages/${PKG}-${VER}/x86_64-conda-linux-gnu-api-v60 ${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten
