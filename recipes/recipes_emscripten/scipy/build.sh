#!/bin/bash

set -e  # Exit the script if any command fails



#############################################################
# write out the cross file
#############################################################
export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"
sed "s|@(NUMPY_INCLUDE_DIR)|${NUMPY_INCLUDE_DIR}|g" $RECIPE_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.cross.temp
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross.temp > $SRC_DIR/emscripten.meson.cross
rm $SRC_DIR/emscripten.meson.cross.temp
echo "THE CROSS FILE"
cat $SRC_DIR/emscripten.meson.cross
echo "END CROSS FILE"


#############################################################
# use pkg-config to find numpy
############################################################# 
export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/lib/pkgconfig"


#############################################################
# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
#############################################################
micromamba install -p $BUILD_PREFIX  conda-forge/label/emscripten::flang libllvm19 --no-channel-priority -y

rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang


############################
# try to compile a simple file
############################
echo "INVOKE FLANG"
$BUILD_PREFIX/bin/flang-new $RECIPE_DIR/test.f90 -o output.obj -D_FILE_OFFSET_BITS=64 -c -g --target=wasm32-unknown-emscripten -O0
echo "INVOKE FLANG DONE"
ls

#############################################################
# patch meson since it otherwise complains with an error that
# emscripten does not support shared libraries ... which is far 
# from the truth
#############################################################
find $BUILD_PREFIX -name linkers.py -exec sed -i "s/raise MesonException(f'{self.id} does not support shared libraries.')/return []/g" {} +


# ############################################################
# # wrap flang-new with a python script
# ############################################################
# mv $BUILD_PREFIX/bin/flang-new $BUILD_PREFIX/bin/flang-new-bak
# cp $RECIPE_DIR/flang_wrapper/flang-new     $BUILD_PREFIX/bin/
# cp $RECIPE_DIR/flang_wrapper/flang-new.py  $BUILD_PREFIX/bin/


#############################################################
# setting up flags
#############################################################
export FC=flang-new
export FFLAGS="-g --target=wasm32-unknown-emscripten"
#  enable WASM_BIGINT to support 64-bit integers and fexceptions to support exceptions
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -fexceptions"
export LDFLAGS=""
export CFLAGS=""
export CXXFLAGS=""
export FCFLAGS=""

#############################################################
# delete all shared libraries from prefix to encourage static linking
#############################################################
# print all libraries
ls $PREFIX/lib/
rm -rf $PREFIX/lib/*.so


#############################################################
# trigger the build
#############################################################
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dblas=blas" \
    -Csetup-args="-Dlapack=lapack" \
    -Csetup-args="-Dfortran_std=none" \
    -Csetup-args="-Dopenmp=false" \
    -Csetup-args="-Duse-pythran=false"
