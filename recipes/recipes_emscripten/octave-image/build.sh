#!/bin/bash
## Start of bash preamble
if [ -z ${CONDA_BUILD+x} ]; then
    source "/Users/thorstenbeier/src/recipes/output/bld/rattler-build_octave-image_1772446917/work/build_env.sh"
fi
## End of preamble


SOURCE_DIR=$(pwd)/image/src
OCTAVE_VER="10.3.0"

CUSTOM_BUILD_DIR=$(pwd)/build
mkdir -p "$CUSTOM_BUILD_DIR"

# compile each *.cc file to a *.oct file using emcc with the appropriate flags
for f in "$SOURCE_DIR"/*.cc; do
    echo "Compiling $f"
    base=$(basename "$f" .cc)
    emcc "$f" -o "${CUSTOM_BUILD_DIR}/${base}.oct" \
        -sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1 \
        -fPIC -O2 \
        -I "$PREFIX/include/octave-${OCTAVE_VER}" 
done



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


# Force mkoctfile to use emcc and the side-module flags
export MKOCTFILE_CC="emcc"
export MKOCTFILE_CXX="em++"

export BUILD_EXEEXT=".js"
export cross_compiling=yes
# Tell the script what the build machine is vs the target
export build_alias="aarch64-apple-darwin"
export host_alias="wasm32-unknown-emscripten"
export MKOCTFILE_DL_LDFLAGS="-sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1"




# Inject the WASM-specific side-module flags into the linker stage
export LDFLAGS="-sSIDE_MODULE=1 -sEXPORT_ALL=1 -sLINKABLE=1"

# Ensure the compiler knows we are in a WASM/PIC environment
export CXXFLAGS="-fPIC -O2"




cp "${RECIPE_DIR}/wasm-ld-wrapper.sh" "$BUILD_PREFIX/bin/wasm-ld"
chmod +x "$BUILD_PREFIX/bin/wasm-ld"

export OCTAVE_HOME=$PREFIX
export OCTAVE_EXEC_HOME=$BUILD_PREFIX
export FCFLAGS="$(strip_cpu_flags "${FCFLAGS:-}")"

# Replace mkoctfile with wrapper inside build env
mv "$BUILD_PREFIX/bin/mkoctfile" "$BUILD_PREFIX/bin/mkoctfile.real"

cp "${RECIPE_DIR}/mkoctfile-wrapper.sh" "$BUILD_PREFIX/bin/mkoctfile"

chmod +x "$BUILD_PREFIX/bin/mkoctfile"

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
pkg prefix '${PREFIX}/share/octave/packages' '${PREFIX}/lib/octave/packages';
pkg install -nodeps ${BUILD_DIR}/*.tar.gz;
pkg list;
"

mv ${PREFIX}/lib/octave/packages/${PKG}-${VER}/x86_64-conda-linux-gnu-api-v60 ${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten

# remove all *.oct files in ${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten
rm ${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten/*.oct

# copy the one we build by hand into the package directory
cp ${CUSTOM_BUILD_DIR}/*.oct ${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten/


echo
echo "==== Checking .oct files for shared memory / pthread usage ===="

OCT_DIR="${PREFIX}/lib/octave/packages/${PKG}-${VER}/wasm32-unknown-emscripten"

FAILED=0

for f in "$OCT_DIR"/*.oct; do
    echo "Inspecting $f"

    if wasm-objdump -x "$f" | grep -q "shared"; then
        echo "Error: shared memory detected in $f"
        FAILED=1
    fi

    if wasm-objdump -x "$f" | grep -iq 'thread\|pthread'; then
        echo "Error: pthread/thread symbols detected in $f"
        FAILED=1
    fi
done

if [ $FAILED -ne 0 ]; then
    echo "Thread/shared memory usage detected — failing build."
    exit 1
fi

echo "No shared memory or pthread usage detected."

# print the size of the .oct files
echo "Sizes of .oct files:"
for f in "$OCT_DIR"/*.oct; do
    ls -lh "$f"
done