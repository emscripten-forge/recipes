#!/bin/bash

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for TASK in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${TASK}.d"
    cp "${RECIPE_DIR}/${TASK}.sh" "${PREFIX}/etc/conda/${TASK}.d/${TASK}_z-${PKG_NAME}.sh"
done


mkdir -p "${PREFIX}/share/cross-python-cmake"
cp $RECIPE_DIR/FindPython.cmake "${PREFIX}/share/cross-python-cmake/FindPython.cmake"