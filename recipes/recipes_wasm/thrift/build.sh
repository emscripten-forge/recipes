#!/bin/bash
set -ex

emcmake cmake ${CMAKE_ARGS} -B build \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBoost_INCLUDE_DIR="${PREFIX}/include" \
  -DBoost_NO_SYSTEM_PATHS=ON \
  -DBoost_NO_BOOST_CMAKE=ON \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_COMPILER=OFF \
  -DBUILD_TESTING=OFF \
  -DBUILD_TUTORIALS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DWITH_CPP=ON \
  -DWITH_PYTHON=OFF \
  -DWITH_JAVA=OFF \
  -DWITH_C_GLIB=OFF \
  -DWITH_AS3=OFF \
  -DWITH_NODEJS=OFF \
  -DWITH_JAVASCRIPT=OFF \
  -DWITH_QT5=OFF \
  -DWITH_OPENSSL=OFF \
  -DWITH_ZLIB=OFF \
  -DWITH_LIBEVENT=OFF

emmake make -C build -j${CPU_COUNT}
emmake make -C build install

# Remove .la files if present
find $PREFIX -name '*.la' -delete

# Install custom CMake config files for easier integration
bash $RECIPE_DIR/install_cmake_config.sh
