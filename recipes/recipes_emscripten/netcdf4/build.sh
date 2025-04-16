#!/bin/bash

# remove the emcc symlink in the $BUILD_PREFIX/bin
rm $BUILD_PREFIX/bin/emcc

# make callable
chmod +x $RECIPE_DIR/emcc_wrapper.sh

# create symlink to $RECIPE_DIR/emcc_wrapper.sh 
ln -s $RECIPE_DIR/emcc_wrapper.sh $BUILD_PREFIX/bin/emcc

${PYTHON} -m pip install .
