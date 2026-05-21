#!/bin/bash

export FC=flang
export F77=flang
export F90=flang
export F95=flang
export F18=flang
export FLANG=flang

export FFLAGS="--target=wasm32-unknown-emscripten"
export FPICFLAGS="-fPIC"
export FCLIBS="-lFortranRuntime"
