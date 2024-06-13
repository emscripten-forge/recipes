#!/bin/bash

set -exuo pipefail

mkdir -p build
cd build

if [[ "${target_platform}" == osx-* ]]; then
    # See https://conda-forge.org/docs/maintainer/knowledge_base.html#newer-c-features-with-old-sdk
    CXXFLAGS="${CXXFLAGS} -D_LIBCPP_DISABLE_AVAILABILITY"
fi

if [[ "$PKG_NAME" == "libabseil-tests" ]]; then
    CMAKE_ARGS="${CMAKE_ARGS} -DBUILD_TESTING=ON -DABSL_BUILD_TESTING=ON"
    CMAKE_ARGS="${CMAKE_ARGS} -DABSL_USE_EXTERNAL_GOOGLETEST=ON -DABSL_FIND_GOOGLETEST=ON"
fi

cmake -GNinja \
    ${CMAKE_ARGS} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_STANDARD=17 \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_PREFIX_PATH=${PREFIX} \
    -DBUILD_SHARED_LIBS=ON \
    -DABSL_PROPAGATE_CXX_STD=ON \
    ..

# Build step
ninja install
