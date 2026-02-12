#!/bin/bash
set -e

export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS"
export LDFLAGS="$LDFLAGS $EM_FORGE_SIDE_MODULE_LDFLAGS"

emcmake cmake -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DBoost_INCLUDE_DIR=$PREFIX/include \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DBUILD_COMPILER=OFF \
  -DBUILD_TESTING=OFF \
  -DBUILD_TUTORIALS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_PYTHON=OFF \
  -DBUILD_JAVA=OFF \
  -DBUILD_C_GLIB=OFF \
  -DBUILD_AS3=OFF \
  -DBUILD_HASKELL=OFF \
  -DBUILD_NODEJS=OFF \
  -DBUILD_JAVASCRIPT=OFF \
  -DENABLE_STATIC=ON \
  -DENABLE_SHARED=OFF \
  -DWITH_OPENSSL=ON \
  -DWITH_ZLIB=ON \
  -DWITH_LIBEVENT=OFF \
  -DWITH_STDTHREADS=OFF

emmake make -C build -j${CPU_COUNT}
emmake make -C build install

# Remove .la files if present
find $PREFIX -name '*.la' -delete

# Install custom CMake config files for easier integration
bash $RECIPE_DIR/install_cmake_config.sh
