#!/bin/bash

# build and host are needed to enable cross-compilation
# The environment LDFLAGS are ignored by the configure script
export CONFIG_ARGS="--prefix=$PREFIX --build=x86_64-conda-linux-gnu --host=wasm32-unknown-emscripten --with-extra-ldflags=-sWASM_BIGINT"

$R CMD INSTALL $R_ARGS --configure-args="$CONFIG_ARGS" --no-byte-compile .
