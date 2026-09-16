#!/bin/bash

export FC=flang
export F77=flang
export F90=flang
export F95=flang
export F18=flang
export FLANG=flang

export TARGET_TRIPLE="${WASM_TARGET}"
export FFLAGS="--target=${WASM_TARGET}"
export FPICFLAGS="-fPIC"
export FCLIBS="-lflang_rt.runtime"

# Intrinsic .mod files (iso_c_binding, etc.) from libflang when installed.
for FINTRINSIC_PATH in "$PREFIX"/lib/clang/*/finclude/flang/"$TARGET_TRIPLE"; do
  if [ -d "$FINTRINSIC_PATH" ]; then
    export FINTRINSIC_MODS="-fintrinsic-modules-path $FINTRINSIC_PATH"
    break
  fi
done
