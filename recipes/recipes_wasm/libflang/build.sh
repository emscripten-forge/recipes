#!/bin/bash

set -e

################################################################################
# BUILD FLANG-RT #
################################################################################

export BUILD_DIR="_build"

# Enable visibility for the shared library
export CFLAGS="$CFLAGS -fPIC -fvisibility=default"
export CXXFLAGS="$CXXFLAGS -fPIC -fvisibility=default"

unset FCLIBS # This is the library we are about to build

# Check target triple is set
if [ -z "$TARGET_TRIPLE" ]; then
    echo "TARGET_TRIPLE is not set"
    exit 1
fi

echo "TARGET_TRIPLE: $TARGET_TRIPLE"

CMAKE_ARGS=(
    -S "./runtimes"
    -B "$BUILD_DIR"
    -GNinja
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DCMAKE_Fortran_COMPILER=flang
    -DCMAKE_Fortran_COMPILER_WORKS=ON
    -DLLVM_ENABLE_RUNTIMES=flang-rt
    -DLLVM_DEFAULT_TARGET_TRIPLE=${TARGET_TRIPLE}
    -DLLVM_INCLUDE_TESTS=OFF
    -DFLANG_RT_INCLUDE_TESTS=OFF
    -DFLANG_RT_ENABLE_SHARED=ON
    -DFLANG_RT_ENABLE_STATIC=ON
    -DFLANG_RUNTIME_F128_MATH_LIB=""
    -DCMAKE_VERBOSE_MAKEFILE=OFF
)


emcmake cmake "${CMAKE_ARGS[@]}"
$(which cmake) --build $BUILD_DIR --target flang-rt
$(which cmake) --build $BUILD_DIR --target install

MAJOR_VERSION="${PKG_VERSION%%.*}"

mv $PREFIX/lib/clang/$MAJOR_VERSION/lib/wasm*-unknown-emscripten/libflang_rt.runtime.* \
    $PREFIX/lib/
