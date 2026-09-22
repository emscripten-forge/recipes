#!/bin/bash

export CFLAGS="$CFLAGS -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS -fwasm-exceptions"
export LDFLAGS="-fwasm-exceptions -L$PREFIX/lib"

if [ -z "$BUILD_SHARED_LIBS" ]; then
    echo "BUILD_SHARED_LIBS is not defined."
    exit 1
fi

mkdir _build
cd _build

emcmake cmake .. -GNinja \
      -Dtiff-tests=OFF \
      -Dtiff-tools=OFF \
      -Dtiff-docs=OFF \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_LIBDIR=lib \
      -DBUILD_SHARED_LIBS=${BUILD_SHARED_LIBS} \
      -DTIFF_STATIC_LIBS_DEFAULT=TRUE \
      -DCMAKE_POSITION_INDEPENDENT_CODE=ON

ninja
ninja install
