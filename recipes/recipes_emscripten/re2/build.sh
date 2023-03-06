#!/bin/bash
set -ex

mkdir build-cmake
pushd build-cmake

emcmake cmake ${CMAKE_ARGS} -GNinja \
  -DCMAKE_PREFIX_PATH=$PREFIX \
  -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
  -DCMAKE_INSTALL_LIBDIR=lib \
  -DRE2_BUILD_TESTING=OFF \
  -DCMAKE_BUILD_TYPE=Release \
  -DBUILD_SHARED_LIBS=OFF \
  ..
ninja install
popd

# Also do this installation to get .pc files. This duplicates the compilation but gets us all necessary components without patching.
emmake make -j "${CPU_COUNT}" prefix=${PREFIX} shared-install
