#!/usr/bin/env bash
set -euxo pipefail

emmake make -j8 \
    GMP_INC_DIR="${PREFIX}/include" \
    CPPFLAGS="-I${PREFIX}/include" \
    LDFLAGS="-L${PREFIX}/lib" \
    CXXFLAGS="-O2 -std=c++14" \
    STRIP="true"

emmake make install PREFIX="${PREFIX}" STRIP="true"
cp bin/release/frobby.wasm "${PREFIX}/bin/"