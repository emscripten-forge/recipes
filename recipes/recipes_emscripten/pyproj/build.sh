#!/bin/bash

# remove the emcc symlink in the $BUILD_PREFIX/bin
rm $BUILD_PREFIX/bin/emcc

# make callable
chmod +x $RECIPE_DIR/emcc_wrapper.sh

# create symlink to $RECIPE_DIR/emcc_wrapper.sh
ln -s $RECIPE_DIR/emcc_wrapper.sh $BUILD_PREFIX/bin/emcc


export PROJ_DIR=$PREFIX

# if version is not set, the python build script
# tries to call the proj binary to get the version
export PROJ_VERSION="9.7.1"

${PYTHON} -m pip install -vv .

