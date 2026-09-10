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
