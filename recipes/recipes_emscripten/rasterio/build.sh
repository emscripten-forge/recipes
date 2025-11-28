#!/bin/bash


embuilder build libjpeg --pic

export EMSCRIPTEN_SYSROOT=$(em-config CACHE)/sysroot
export EMSCRIPTEN_INCLUDE=$EMSCRIPTEN_SYSROOT/include
export EMSCRIPTEN_LIB=$EMSCRIPTEN_SYSROOT/lib/wasm32-emscripten/pic


# add EMSCRIPTEN_INCLUDE to include in CFLAGS
export CFLAGS="$CFLAGS -I${EMSCRIPTEN_INCLUDE} -fPIC"

# add EMSCRIPTEN_LIB to lib path in LDFLAGS
export LDFLAGS="$LDFLAGS -L${EMSCRIPTEN_LIB} -fPIC"

${PYTHON} -m pip install . ${PIP_ARGS}
