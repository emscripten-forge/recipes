#!/bin/bash
set -ex

export CFLAGS="${CFLAGS} ${EM_FORGE_SIDE_MODULE_CFLAGS}"
export LDFLAGS="${LDFLAGS} ${EM_FORGE_SIDE_MODULE_LDFLAGS}"

# Build librebound as a shared library (wasm side module).
# SERVER is disabled in the patch because it uses POSIX sockets
# and pthreads, which are not available on emscripten.
cd src
emcc ${CFLAGS} -shared -o librebound.so \
    *.c \
    -I. \
    -lm \
    -sEXPORT_ALL=1 \
    ${LDFLAGS}

# Install library and headers
mkdir -p ${PREFIX}/lib ${PREFIX}/include
cp librebound.so ${PREFIX}/lib/
cp *.h ${PREFIX}/include/
