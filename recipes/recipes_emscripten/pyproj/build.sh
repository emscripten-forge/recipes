#!/bin/bash

# remove the emcc symlink in the $BUILD_PREFIX/bin
rm $BUILD_PREFIX/bin/emcc

# make callable
chmod +x $RECIPE_DIR/wasm-ld-wrapper.sh

# create symlink to $RECIPE_DIR/wasm-ld-wrapper.sh 
ln -s $RECIPE_DIR/wasm-ld-wrapper.sh $BUILD_PREFIX/bin/emcc


# # the binary is needed ....
# cp $BUILD_PREFIX/bin/proj $PREFIX/bin/proj
export PROJ_DIR=$PREFIX

# if version is not set, the python build script
# tries to call the proj binary to get the version
export PROJ_VERSION="9.4.1"

${PYTHON} -m pip install -vv .


# restore the original emcc
mv $orginal_emsdk_dir/emcc_orginal $orginal_emsdk_dir/emcc