#!/bin/bash
set -e

if [ -z "${BUILD_SHARED_LIBS}" ]; then
    echo "BUILD_SHARED_LIBS must be set to ON or OFF"
    exit 1
fi

export CFLAGS="$CFLAGS -fwasm-exceptions -fPIC"
export LDFLAGS="$LDFLAGS -fwasm-exceptions -fPIC"
export CXXFLAGS="$CXXFLAGS -fwasm-exceptions -fPIC"

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} \
      -DDISABLE_GEOS_INLINE=ON \
      -DBUILD_TESTING=OFF \
      -DBUILD_BENCHMARKS=OFF \
      -DBUILD_DOCUMENTATION=OFF \
      -DBUILD_GEOSOP=OFF \
      ..

emmake make -j${CPU_COUNT}

emmake make install -j${CPU_COUNT}
