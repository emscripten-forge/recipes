#!/usr/bin/env bash
set -euxo pipefail

WASM_CFLAGS="-I../include -Ofast -DBIT64 -DUSESIGTERM -Wno-implicit-function-declaration"
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

cp solver/csdp "${PREFIX}/bin/"
cp solver/csdp.wasm "${PREFIX}/bin/"
cp theta/theta "${PREFIX}/bin/"
cp theta/theta.wasm "${PREFIX}/bin/"
cp theta/graphtoprob "${PREFIX}/bin/"
cp theta/graphtoprob.wasm "${PREFIX}/bin/"
cp theta/complement "${PREFIX}/bin/"
cp theta/complement.wasm "${PREFIX}/bin/"
cp theta/rand_graph "${PREFIX}/bin/"
cp theta/rand_graph.wasm "${PREFIX}/bin/"