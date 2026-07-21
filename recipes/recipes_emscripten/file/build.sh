#!/usr/bin/env bash
set -exo pipefail

# Get an updated config.sub and config.guess
cp $BUILD_PREFIX/share/gnuconfig/config.* .

configure_args=(
    --prefix="${PREFIX}"
    --datadir="${PREFIX}/share"
    --disable-silent-rules
    --disable-dependency-tracking
    --disable-shared
    LDFLAGS="$LDFLAGS -sMODULARIZE=1"
)

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" == "1" ]]; then
    CC=$CC_FOR_BUILD CFLAGS=$CFLAGS_FOR_BUILD ./configure \
        --build=${BUILD} \
        --host=${BUILD} \
        --prefix="${BUILD_PREFIX}" \
        --datadir="${BUILD_PREFIX}/share" \
        --disable-silent-rules \
        --disable-dependency-tracking

    make "-j${CPU_COUNT}"
    (cd src && make clean)
fi

emconfigure ./configure "${configure_args[@]}"

(cd src && emmake make "-j${CPU_COUNT}")
(cd magic && touch magic.mgc)
emmake make "-j${CPU_COUNT}"

emmake make install

find src -name "file.js" -exec cp {} $PREFIX/bin/ \;
find src -name "file.wasm" -exec cp {} $PREFIX/bin/ \;
