#!/usr/bin/env bash
set -euxo pipefail

export CFLAGS="${CFLAGS:-} -Wno-implicit-function-declaration -fPIC"

export CC="emcc"
export CXX="em++"
export AR="emar"
export RANLIB="emranlib"

GMP_FLAGS="-DGMP -I${PREFIX}/include -L${PREFIX}/lib -lgmp"

emmake make liblrs.a lrsgmp \
    CC="${CC}" \
    CXX="${CXX}" \
    AR="${AR}" \
    RANLIB="${RANLIB}" \
    GMP="${GMP_FLAGS}" \
    INCLUDEDIR="${PREFIX}/include" \
    LIBDIR="${PREFIX}/lib"

mkdir -p "${PREFIX}/include"
mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/bin"

cp *.h "${PREFIX}/include/"

cp liblrs.a "${PREFIX}/lib/"
if [ -f liblrsgmp.a ]; then
    cp liblrsgmp.a "${PREFIX}/lib/"
fi

shopt -s nullglob
for f in lrsgmp lrs *.wasm *.js; do
    if [ -f "$f" ]; then
        cp "$f" "${PREFIX}/bin/"
    fi
done
shopt -u nullglob
