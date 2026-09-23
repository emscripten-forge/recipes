#!/bin/bash

set -ex

mkdir -p build
cd build

unset cmake

emcmake cmake -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=${PREFIX} \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=${PREFIX}/lib \
      -DCMAKE_INSTALL_RPATH=${PREFIX}/lib \
      -DENABLE_SHARED=ON \
      -DENABLE_STATIC=ON \
      ${CMAKE_ARGS} ${SRC_DIR}

make -j${CPU_COUNT} ${VERBOSE_CM}

make -j${CPU_COUNT} install

cp ./lzopack.wasm  $PREFIX/libexec/lzo/examples/
cp ./lzotest.wasm  $PREFIX/libexec/lzo/examples/
cp ./simple.wasm   $PREFIX/libexec/lzo/examples/
cp ./testmini.wasm $PREFIX/libexec/lzo/examples/