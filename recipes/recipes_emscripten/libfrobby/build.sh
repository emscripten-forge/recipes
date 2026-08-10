#!/usr/bin/env bash
set -euxo pipefail

emmake make library -j8 \
    GMP_INC_DIR="${PREFIX}/include" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CXXFLAGS="-O2 -std=c++14" \
    STRIP="true"

cp bin/libfrobby.a "${PREFIX}/lib/"
cp src/frobby.h "${PREFIX}/include/"