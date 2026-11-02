#!/bin/bash

set -eux

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  WASM_TARGET="wasm64-unknown-emscripten"
elif [[ "${target_platform}" == "emscripten-wasm32" ]]; then
  WASM_TARGET="wasm32-unknown-emscripten"
else
  echo "Unsupported target_platform: $target_platform"
  exit 1
fi

################################################################################
# Patched LLVM + Flang toolchain
################################################################################

export LLVM_DIR="$BUILD_PREFIX/lib/llvm-toolchain"
export PATH="$LLVM_DIR/bin:$PATH"

# Remove the link to Emscripten's wasm-ld
rm $BUILD_PREFIX/bin/wasm-ld
ln -s $LLVM_DIR/bin/lld $BUILD_PREFIX/bin/wasm-ld

# Set flags (same as Flang's activation script)
export EM_LLVM_ROOT=$LLVM_DIR
export FLANG=$LLVM_DIR/bin/flang
export FC=$FLANG
export F77=$FLANG
export F90=$FLANG
export F95=$FLANG
export F18=$FLANG
export FFLAGS="--target=${WASM_TARGET}"
export FPICFLAGS="-fPIC"
export FCLIBS="-lflang_rt.runtime"

################################################################################

$R CMD INSTALL $R_ARGS .