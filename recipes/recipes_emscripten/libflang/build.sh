#!/bin/bash

set -ex

export CFLAGS="$CFLAGS -fPIC"
export CXXFLAGS="$CXXFLAGS -fPIC"

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
emcmake cmake -S flang/runtime -B _fbuild_runtime -GNinja \
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
