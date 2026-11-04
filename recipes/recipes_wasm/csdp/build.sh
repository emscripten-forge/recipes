#!/usr/bin/env bash
set -euxo pipefail

# HIDDENSTRLEN: the flang-built openblas takes the Fortran hidden string length
# arguments (see patches/0001), which a wasm call has to pass with the exact
# signature
WASM_CFLAGS="-I../include -Ofast -DBIT64 -DUSESIGTERM -DHIDDENSTRLEN -Wno-implicit-function-declaration ${CFLAGS:-}"
WASM_LIBS="-L../lib -lsdp -L${PREFIX}/lib -lopenblas -lm"

emmake make all \
    CC="emcc" \
    AR="emar" \
    CFLAGS="${WASM_CFLAGS}" \
    LIBS="${WASM_LIBS}"

mkdir -p "${PREFIX}/bin"
mkdir -p "${PREFIX}/lib"
mkdir -p "${PREFIX}/include"

cp lib/libsdp.a "${PREFIX}/lib/"
cp include/*.h "${PREFIX}/include/"

for prog in solver/csdp theta/theta theta/graphtoprob theta/complement theta/rand_graph; do
    cp "${prog}" "${PREFIX}/bin/"
    cp "${prog}.wasm" "${PREFIX}/bin/"
done
