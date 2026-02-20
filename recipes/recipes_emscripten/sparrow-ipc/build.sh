#!/bin/bash
set -e

export CXXFLAGS="${CXXFLAGS} -fPIC"

# Create build directory
mkdir -p build
cd build

# Copy zstd CMake config to a location CMake will find
mkdir -p $PREFIX/lib/cmake/zstd
cp ${RECIPE_DIR}/zstdConfig.cmake $PREFIX/lib/cmake/zstd/

# Configure the build with CMake
emcmake cmake .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DUSE_DATE_POLYFILL=ON \
  -Dflatbuffers_DIR=$PREFIX/lib/cmake/flatbuffers \
  -Dzstd_DIR=$PREFIX/lib/cmake/zstd \
  -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
  -DSPARROW_IPC_BUILD_SHARED=OFF

# Build step
emmake make -j8

emcc bin/Release/libsparrow-ipc.a \
  $EM_FORGE_SIDE_MODULE_LDFLAGS \
  -o libsparrow-ipc.so

# Install step
emmake make install -j8

cp libsparrow-ipc.so "$PREFIX/lib/"

cp -r ../include/sparrow_ipc "$PREFIX/include/"
rm -rf "$PREFIX/include/include/sparrow_ipc"
