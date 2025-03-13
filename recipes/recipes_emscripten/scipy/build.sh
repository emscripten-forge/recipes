#!/bin/bash

set -e  # Exit the script if any command fails

#############################################################
# copy patched / custom code for subprojects/submodules
#############################################################
echo "CONTENT OF custom_submodules/PROPACK"
ls $SRC_DIR/custom_submodules/PROPACK

echo "remove the original propack"
rm -rf $SRC_DIR/scipy/sparse/linalg/_propack/PROPACK     

echo "copy the custom propack"
cp -r $SRC_DIR/custom_submodules/PROPACK $SRC_DIR/scipy/sparse/linalg/_propack/

echo "CONTENT OF scipy/sparse/linalg/_propack"
ls $SRC_DIR/scipy/sparse/linalg/_propack


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
export PKG_CONFIG_PATH="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/lib/pkgconfig"


#############################################################
# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
#############################################################
micromamba install -p $BUILD_PREFIX  conda-forge/label/emscripten::flang libllvm19 --no-channel-priority -y

rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang


#############################################################
# copy numpy headers from host to the build environment
#############################################################
# note this should actually be done by the cross-python script
# but it is not working (in particular when doing debug builds)


if [ -d "$PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/numpy" ]; then
    echo "Copying numpy headers from host to the build environment"
    mkdir -p $BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/numpy
    cp -r $PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/numpy $BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/

else
    echo "numpy headers not found in $PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include/numpy"
fi

if [ -d "$PREFIX/include/python${PY_VER}" ]; then
    mkdir -p $BUILD_PREFIX/include/
    echo "Copying python headers from host to the build environment"
    cp -r $PREFIX/include/python${PY_VER} $BUILD_PREFIX/include/
else
    echo "python headers not found in $PREFIX/include/python${PY_VER}"
fi



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
#############################################################  
export FFLAGS="-g --target=wasm32-unknown-emscripten -fno-common"
#  enable WASM_BIGINT to support 64-bit integers and fexceptions to support exceptions
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -fexceptions"
export LDFLAGS="-fno-common"
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
    -Csetup-args="-Duse-pythran=false" \
    -Csetup-args="-Duse-g77-abi=true" 
