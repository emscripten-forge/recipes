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

rm -f "$BUILD_PREFIX/bin/wasm-ld"

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
octave -W -H --eval "pkg build ${BUILD_DIR} ${PKG}-${VER}.tar.gz -verbose"

# ------------------------------------------------------------------
# Manual install into $PREFIX
# ------------------------------------------------------------------

PKG_BUILD_DIR=$(find "${BUILD_DIR}" -maxdepth 1 -mindepth 1 -type d | head -n 1)

if [[ -z "${PKG_BUILD_DIR}" ]]; then
  echo "ERROR: No build directory found inside ${BUILD_DIR}"
  exit 1
fi

echo "Using PKG_BUILD_DIR=${PKG_BUILD_DIR}"

log "Detecting Octave canonical host type"

OCT_ARCH=$(octave -q --eval "printf('%s', octave_config_info('canonical_host_type'))")
echo "OCT_ARCH=${OCT_ARCH}"

LIB_DEST="${PREFIX}/lib/octave/packages/${PKG}-${VER}/${OCT_ARCH}"
SHARE_DEST="${PREFIX}/share/octave/packages/${PKG}-${VER}"

log "Creating destination directories"

mkdir -p "${LIB_DEST}"
mkdir -p "${SHARE_DEST}"

log "Copying compiled .oct files"

find "${PKG_BUILD_DIR}" -type f -name "*.oct" -exec cp {} "${LIB_DEST}/" \;

log "Copying PKG_ADD and PKG_DEL if present"

for f in PKG_ADD PKG_DEL; do
  if [[ -f "${PKG_BUILD_DIR}/${f}" ]]; then
    cp "${PKG_BUILD_DIR}/${f}" "${LIB_DEST}/"
  fi
done

log "Copying all remaining package content to share/"

rsync -a \
  --exclude="*.oct" \
  "${PKG_BUILD_DIR}/" \
  "${SHARE_DEST}/"

log "Manual installation complete"

log "Final installed tree"
find "${PREFIX}/lib/octave/packages/${PKG}-${VER}" -maxdepth 3 || true
find "${PREFIX}/share/octave/packages/${PKG}-${VER}" -maxdepth 3 || true


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
