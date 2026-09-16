#!/usr/bin/env bash
set -euxo pipefail

make checkdirs

emmake make -j8 \
    CC="${CC}" \
    CXX="${CXX}" \
    LD="true" \
    CFLAGS="${CFLAGS:-}" \
    CXXFLAGS="${CXXFLAGS:-}"

emar rcs libcohomcalg.a build/*.o build/polylib_mod/*.o

mkdir -p "${PREFIX}/lib" "${PREFIX}/include"
cp libcohomcalg.a "${PREFIX}/lib/"
cp source/*.h "${PREFIX}/include/"