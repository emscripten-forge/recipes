#!/bin/bash
set -e

# Set compiler flags for standalone executable (not side module)
export CFLAGS="$CFLAGS $EM_FORGE_CFLAGS_BASE -I${PREFIX}/include"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_CFLAGS_BASE -I${PREFIX}/include"
export LDFLAGS="$LDFLAGS $EM_FORGE_LDFLAGS_BASE"

if [ -f "$PREFIX/lib/libz.so" ]; then
    STATIC_ZLIB=OFF
else
    STATIC_ZLIB=ON
fi

# Build the tests
emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DSTATIC_ZLIB=$STATIC_ZLIB \
    -DZLIB_DIR=$PREFIX/lib/cmake/zlib

emmake ninja -C build_tests


# if there is a $PREFIX/lib/zlib.so, we need to copy it to the build_tests directory, because the tests will look for it there
if [ -f "$PREFIX/lib/libz.so" ]; then
    cp "$PREFIX/lib/libz.so" build_tests/
fi

# Run the tests
echo "Running zlib tests..."
node build_tests/test_zlib.js
