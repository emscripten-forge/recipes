#!/usr/bin/env bash

set -eux

# Build the bundled libsodium for wasm32 ourselves: the sdist's setup.py runs
# its configure without --host, which autoconf treats as a native build.
export SODIUM_PREFIX="${SRC_DIR}/libsodium-install"
pushd "${SRC_DIR}/src/libsodium"
    ac_cv_func_memset_s=no emconfigure ./configure \
        --host=wasm32-unknown-emscripten \
        --prefix="${SODIUM_PREFIX}" \
        --disable-shared \
        --enable-static \
        --disable-debug \
        --disable-dependency-tracking \
        --with-pic
    emmake make -j${CPU_COUNT}
    emmake make install
popd

export SODIUM_INSTALL=system
export FLAGS="-DNDEBUG -fPIC -sWASM_BIGINT -s SIDE_MODULE=1 -fwasm-exceptions"
export CFLAGS="${CFLAGS:-} ${FLAGS} -I${SODIUM_PREFIX}/include"
export LDFLAGS="${LDFLAGS:-} -fwasm-exceptions -sWASM_BIGINT -L${SODIUM_PREFIX}/lib"

$PYTHON -m pip install . --no-deps --no-build-isolation ${PIP_ARGS} -vv
