#!/usr/bin/env bash
set -euxo pipefail

export ac_cv_func_malloc_0_nonnull=yes
export ac_cv_func_realloc_0_nonnull=yes
export HELP2MAN=/bin/true

autoreconf -vfi

mkdir build-native
pushd build-native
CC=${CC_FOR_BUILD:-gcc} \
CXX=${CXX_FOR_BUILD:-g++} \
AR=${AR_FOR_BUILD:-ar} \
RANLIB=${RANLIB_FOR_BUILD:-ranlib} \
LD=${LD_FOR_BUILD:-ld} \
NM=${NM_FOR_BUILD:-nm} \
CFLAGS="" \
CXXFLAGS="" \
CPPFLAGS="" \
LDFLAGS="" \
../configure
make -j8
popd

export CPPFLAGS="-I${PREFIX}/include"
export LDFLAGS="-L${PREFIX}/lib"
export CXXFLAGS="-std=c++11"
export CFLAGS="-Wno-implicit-function-declaration"

mkdir build-wasm
pushd build-wasm
emconfigure ../configure \
    --build=i686-pc-linux-gnu \
    --host=wasm32-unknown-emscripten \
    --disable-shared \
    --enable-static \
    --prefix="${PREFIX}"

mkdir -p src
cp ../build-native/src/stage1scan.c src/
touch src/stage1scan.c

touch ../src/scan.c

emmake make -j8
emmake make install

cp src/*.wasm "${PREFIX}/bin/" || true
popd