#!/bin/bash
set -e

mkdir -p build
cd build

# Shared library: python-soundfile loads libsndfile at runtime via cffi.
# No FLAC/Vorbis/Opus/MPEG codec libraries exist for emscripten-forge yet.
emcmake cmake ${CMAKE_ARGS} .. \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DBUILD_SHARED_LIBS=ON \
  -DENABLE_EXTERNAL_LIBS=OFF \
  -DENABLE_MPEG=OFF \
  -DBUILD_PROGRAMS=OFF \
  -DBUILD_EXAMPLES=OFF \
  -DBUILD_TESTING=OFF \
  -DENABLE_CPACK=OFF \
  -DCMAKE_POLICY_VERSION_MINIMUM=3.5

emmake make -j${CPU_COUNT}
emmake make install
