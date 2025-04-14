#!/bin/bash

set -ex

# FIXME: This is the old runtime library compiled with em-3.1.45
# `libflang` does not produce a compatible library.
# See: https://github.com/emscripten-forge/recipes/pull/2046
cp $RECIPE_DIR/libFortranRuntime_emscripten-wasm32.a $PREFIX/lib/

mkdir -p $PREFIX/etc/conda/activate.d
mkdir -p $PREFIX/etc/conda/deactivate.d

cp $RECIPE_DIR/activate-flang_emscripten-wasm32.sh $PREFIX/etc/conda/activate.d/
cp $RECIPE_DIR/deactivate-flang_emscripten-wasm32.sh $PREFIX/etc/conda/deactivate.d/
