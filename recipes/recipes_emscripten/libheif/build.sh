#!/bin/bash

mkdir build
cd build

# Configure with CMake for emscripten with minimal dependencies
emcmake cmake .. \
  -GNinja \
  -DCMAKE_INSTALL_PREFIX=${PREFIX} \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  -DBUILD_TESTING=OFF \
  -DENABLE_PLUGIN_LOADING=OFF \
  -DWITH_EXAMPLES=OFF \
  -DWITH_TOOLS=OFF \
  -DWITH_LIBDE265=OFF \
  -DWITH_X265=OFF \
  -DWITH_AOM=OFF \
  -DWITH_DAV1D=OFF \
  -DWITH_SvtEnc=OFF \
  -DWITH_RAV1E=OFF \
  -DWITH_KVAZAAR=OFF \
  -DWITH_UVG266=OFF \
  -DWITH_VVDEC=OFF \
  -DWITH_VVENC=OFF \
  -DWITH_OpenH264=OFF \
  -DWITH_FFMPEG=OFF \
  -DWITH_JPEG=OFF \
  -DWITH_OpenJPEG=OFF \
  -DWITH_OPENJPH=OFF

ninja
ninja install
