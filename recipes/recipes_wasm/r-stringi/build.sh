#!/bin/bash

if [[ "${target_platform}" == "emscripten-wasm64" ]]; then
  HOST="wasm64-unknown-emscripten"
else
  HOST="wasm32-unknown-emscripten"
fi

# build and host are needed to enable cross-compilation
# The environment LDFLAGS are ignored by the configure script
export CONFIG_ARGS="--prefix=$PREFIX --build=x86_64-conda-linux-gnu --host=$HOST"

$R CMD INSTALL $R_ARGS --configure-args="$CONFIG_ARGS" --no-byte-compile .
