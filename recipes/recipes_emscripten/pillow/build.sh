#!/bin/bash
set -e

export CFLAGS="${CFLAGS} -sRELOCATABLE=1 -fexceptions"
export LDFLAGS="${LDFLAGS} -sRELOCATABLE=1 -fexceptions"
export CXXFLAGS="${CXXFLAGS} -sRELOCATABLE=1 -fexceptions"

# pushd $CONDA_EMSDK_DIR
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build freetype --pic
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build libjpeg --pic
# popd

export LDFLAGS="${LDFLAGS} -s USE_LIBJPEG"
export CFLAGS="${CFLAGS} -s USE_ZLIB=1 -s USE_LIBJPEG=1 -s USE_FREETYPE=1 -s SIDE_MODULE=1 -I${PREFIX}/include"
export DISABLE_BCN=1

export EMSCRIPTEN_INCLUDE_PATH=$(em-config CACHE)/sysroot/include/
export EMSCRIPTEN_LIBRARY_PATH=$(em-config CACHE)/sysroot/lib/wasm32-emscripten/pic/
export CFLAGS="${CFLAGS} -I${EMSCRIPTEN_INCLUDE_PATH}  -L${EMSCRIPTEN_LIBRARY_PATH}"


DISABLE_PLATFORM_GUESSING=1 ${PYTHON} -m pip  install . -vvv


rm -rf $PREFIX/bin
