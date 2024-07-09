#!/bin/bash

# # override the wasm-ld command to a wrapper 
# # otherwise -R gets passed as flag
# alias emcc=$PWD"/wasm-ld-wrapper.sh"

orginal_emsdk=$(which emcc)

# dir of the orginal emcc
orginal_emsdk_dir=$(dirname $orginal_emsdk)


# make a copy of the original emcc
cp $orginal_emsdk $(orginal_emsdk_dir)/emcc_orginal

# override the emcc command to a wrapper
# otherwise -R gets passed as flag
cp $RECIPE_DIR/wasm-ld-wrapper.sh  $orginal_emsdk_dir/emcc


# # the binary is needed ....
# cp $BUILD_PREFIX/bin/proj $PREFIX/bin/proj
export PROJ_DIR=$PREFIX

# if version is not set, the python build script
# tries to call the proj binary to get the version
export PROJ_VERSION="9.4.1"

${PYTHON} -m pip install -vv .


# restore the original emcc
mv $orginal_emsdk_dir/emcc_orginal $orginal_emsdk_dir/emcc