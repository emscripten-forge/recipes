#!/bin/bash

mkdir -p build && cd build

emcmake cmake ${CMAKE_ARGS} \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_INSTALL_PREFIX=${PREFIX} \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=OFF \
      ..

emmake make -j${CPU_COUNT} #${VERBOSE_CM}

if [[ "${OSX_ARCH}" = "x86_64" ]]; then
    # See https://github.com/libgeos/geos/issues/930
    CTEST_EXCLUDE=unit-geom-Envelope
fi

if [[ "${CONDA_BUILD_CROSS_COMPILATION}" != "1" ]]; then
    ctest --output-on-failure --exclude-regex ${CTEST_EXCLUDE}
fi

emmake make install -j${CPU_COUNT}
#ctest
