#!/usr/bin/env bash
set -euxo pipefail

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"

# --disable-threads: no pthreads (xz's multi-threaded compression)
emconfigure ./configure \
    --build="${BUILD}" \
    --host="${HOST}" \
    --disable-shared \
    --enable-static \
    --disable-threads \
    --disable-xzdec \
    --disable-lzmadec \
    --disable-lzmainfo \
    --disable-lzma-links \
    --disable-scripts \
    --disable-doc \
    --disable-nls \
    --prefix="${SRC_DIR}/_install"

emmake make -j"${CPU_COUNT:-2}"
emmake make install

# Only the xz program is packaged: liblzma (library + headers) comes from the
# liblzma-static package; xz links its own copy statically.
mkdir -p "${PREFIX}/bin"
cp src/xz/xz "${PREFIX}/bin/xz"
cp src/xz/xz.wasm "${PREFIX}/bin/xz.wasm"
