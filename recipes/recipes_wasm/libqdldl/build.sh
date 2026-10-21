#!/bin/bash
set -euxo pipefail

mkdir -p build
cd build

# Initially compile with QDLDL_BUILD_STATIC_LIB ON to run tests
emcmake cmake ${CMAKE_ARGS} .. \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DCMAKE_INSTALL_SYSTEM_RUNTIME_LIBS_SKIP=True \
      -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake \
      -DBUILD_SHARED_LIBS=ON \
      -DQDLDL_BUILD_SHARED_LIB=ON \
      -DQDLDL_BUILD_STATIC_LIB=ON \
      -DQDLDL_BUILD_DEMO_EXE=OFF \
      -DBUILD_TESTING=ON \
      -DQDLDL_UNITTESTS=ON \
      -DQDLDL_LONG=ON

emmake make -j${CPU_COUNT}

# Upstream unit tests link against the static library; run them under Node.
node out/qdldl_tester.js

# Re-configure with QDLDL_BUILD_STATIC_LIB OFF to install only shared library
emcmake cmake \
      -DQDLDL_BUILD_SHARED_LIB=ON \
      -DQDLDL_BUILD_STATIC_LIB=OFF \
      -DQDLDL_UNITTESTS=OFF \
      .
emmake make -j${CPU_COUNT} install
