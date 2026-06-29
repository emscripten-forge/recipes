#!/usr/bin/env bash
set -euxo pipefail

sed -i 's/bool operator==(iterator it)/bool operator==(const iterator\& it)/g' src/mathic/DivList.h
sed -i 's/bool operator!=(iterator it)/bool operator!=(const iterator\& it)/g' src/mathic/DivList.h

sed -i 's/struct Bucket/public: struct Bucket/g' src/mathic/Geobucket.h

./autogen.sh

CPPFLAGS="-I${PREFIX}/include" \
LDFLAGS="-L${PREFIX}/lib" \
CXXFLAGS="-std=gnu++0x" \
emconfigure ./configure \
    --host=wasm32-unknown-emscripten \
    --with-gtest=no \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}" \
    MEMTAILOR_CFLAGS="-I${PREFIX}/include" \
    MEMTAILOR_LIBS="-L${PREFIX}/lib -lmemtailor"

emmake make -j8
emmake make install