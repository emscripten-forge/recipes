#!/bin/bash

set -ex

export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# LLVM 21 moved the runtime from flang/runtime to flang-rt/lib/runtime
# and requires cmake module path for the new flang-rt build infrastructure
emcmake cmake -S flang-rt/lib/runtime -B _fbuild_runtime -GNinja \
                -DCMAKE_MODULE_PATH="$(pwd)/flang-rt/cmake/modules;$(pwd)/flang/cmake/modules" \
                -DFLANG_RT_SOURCE_DIR="$(pwd)/flang-rt" \
                -DFLANG_SOURCE_DIR="$(pwd)/flang" \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_runtime
$(which cmake) --build _fbuild_runtime --target install


# Build libFortranDecimal.a
emcmake cmake -S flang/lib/Decimal -B _fbuild_decimal -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_decimal
$(which cmake) --build _fbuild_decimal --target install
