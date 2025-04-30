#!/bin/bash

set -ex

# FIXME: This is the old runtime library compiled with em-3.1.45
# `libflang` does not produce a compatible library.
# See: https://github.com/emscripten-forge/recipes/pull/2046
cp $RECIPE_DIR/libFortranRuntime_emscripten-wasm32.a $PREFIX/lib/

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${TASK}.sh" > "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
done