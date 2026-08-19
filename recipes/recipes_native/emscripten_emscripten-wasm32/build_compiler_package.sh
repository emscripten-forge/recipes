#!/bin/bash

mkdir -p "${PREFIX}/bin"

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${TASK}.sh" > "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh"
    cp "${PREFIX}/etc/conda/${TASK}.d/${TASK}_${PKG_NAME}.sh" "${PREFIX}/bin/${TASK}_emscripten_32.sh"
done


