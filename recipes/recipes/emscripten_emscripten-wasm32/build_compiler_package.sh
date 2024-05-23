#!/bin/bash

# Copy the [de]activate scripts to $PREFIX/etc/conda/[de]activate.d.
# This will allow them to be run on environment activation.
for CHANGE in "activate" "deactivate"
do
    mkdir -p "${PREFIX}/etc/conda/${CHANGE}.d"
    envsubst '$PKG_VERSION' < "${RECIPE_DIR}/${CHANGE}.sh" > "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh"
done

mkdir -p ${PREFIX}/bin
cp "${PREFIX}/etc/conda/${CHANGE}.d/${PKG_NAME}_${CHANGE}.sh" ${PREFIX}/bin/activate_emscripten.sh

./emsdk install $PKG_VERSION

# export EMSDK=/Users/wolfv/Programs/emscripten-forge/emscripten_forge_emsdk_install
export EMSDK=.

mkdir -p $PREFIX/opt/emsdk/
cp -r $EMSDK/upstream $PREFIX/opt/emsdk/upstream
rm -rf $PREFIX/opt/emsdk/upstream/emscripten/test/

mkdir -p $PREFIX/bin

for file in $PREFIX/opt/emsdk/upstream/bin/*; do
    echo "Linking $file"
    ln -s $file $PREFIX/bin/
done