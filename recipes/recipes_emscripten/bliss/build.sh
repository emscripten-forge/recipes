#!/usr/bin/env bash
set -euxo pipefail

export CFLAGS="-I$PREFIX/include $(echo "${CFLAGS:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g')"
export CXXFLAGS="-I$PREFIX/include $(echo "${CXXFLAGS:-}" | sed -E 's/-march=[^ ]+//g; s/-mtune=[^ ]+//g')"
export LDFLAGS="-L$PREFIX/lib ${LDFLAGS:-}"

emcmake cmake -S . -B build \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_BUILD_TYPE=Release \
    -DUSE_GMP=ON \
    -DGMP_LIBRARIES=$PREFIX/lib/libgmp.a \
    -DBUILD_SHARED_LIBS=OFF

cd build
emmake make -j${CPU_COUNT:-1}

mkdir -p $PREFIX/lib
mkdir -p $PREFIX/include/bliss
mkdir -p $PREFIX/bin

cp libbliss.a $PREFIX/lib/
cp libbliss_static.a $PREFIX/lib/ || true

cp ../src/*.hh $PREFIX/include/bliss/

cp bliss.js $PREFIX/bin/
cp bliss.wasm $PREFIX/bin/