#!/bin/bash

set -ex

# See https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
emcmake cmake -S flang/runtime -B _fbuild_runtime -GNinja \
                -DCMAKE_BUILD_TYPE=Release \
                -DCMAKE_INSTALL_PREFIX=$PREFIX
$(which cmake) --build _fbuild_runtime
$(which cmake) --build _fbuild_runtime --target install
