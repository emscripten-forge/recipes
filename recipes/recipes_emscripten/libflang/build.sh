#!/bin/bash

set -ex

################################################################################
# BUILD FLANG-RT #
################################################################################

export BUILD_DIR="_build"
export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

CMAKE_ARGS=(
    -S "./runtimes"
    -B "$BUILD_DIR"
    -GNinja
    -DCMAKE_BUILD_TYPE=Release
    -DCMAKE_INSTALL_PREFIX="$PREFIX"
    -DLLVM_ENABLE_RUNTIMES=flang-rt
    -DCMAKE_Fortran_COMPILER=flang
    -DCMAKE_Fortran_COMPILER_WORKS=ON
    -DLLVM_DEFAULT_TARGET_TRIPLE=wasm32-unknown-emscripten
    -DFLANG_RT_INCLUDE_TESTS=OFF
    -DLLVM_INCLUDE_TESTS=OFF
    -DFLANG_RUNTIME_F128_MATH_LIB=""
    -DCMAKE_VERBOSE_MAKEFILE=OFF
)


emcmake cmake "${CMAKE_ARGS[@]}"
$(which cmake) --build $BUILD_DIR --target flang-rt
$(which cmake) --build $BUILD_DIR --target install

ln -s $PREFIX/lib/clang/22/lib/wasm32-unknown-emscripten/libflang_rt.runtime.a \
    $PREFIX/lib/libflang_rt.runtime.a

export LDFLAGS="-L$PREFIX/lib -lflang_rt.runtime"

# Test the library
flang $FFLAGS -c $RECIPE_DIR/hello.f90 -o hello.o
emcc hello.o $LDFLAGS -o hello.js -sEXIT_RUNTIME=1
node hello.js | grep -F "Hello, Fortran!"

################################################################################
# BUILD libFortranDecimal #
################################################################################

# # Build libFortranDecimal.a
# export BUILD_DECIMAL="_build_decimal"
# emcmake cmake -S flang/lib/Decimal -B $BUILD_DECIMAL -GNinja \
#                 -DCMAKE_BUILD_TYPE=Release \
#                 -DCMAKE_INSTALL_PREFIX=$PREFIX
# $(which cmake) --build $BUILD_DECIMAL
# $(which cmake) --build $BUILD_DECIMAL --target install
