#!/bin/bash

set -e  # Exit the script if any command fails


export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"

# write out the cross file
sed "s|@(NUMPY_INCLUDE_DIR)|${NUMPY_INCLUDE_DIR}|g" $RECIPE_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.cross.temp
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross.temp > $SRC_DIR/emscripten.meson.cross
rm $SRC_DIR/emscripten.meson.cross.temp

echo "THE CROSS FILE"
cat $SRC_DIR/emscripten.meson.cross
echo "END CROSS FILE"



# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-20 $BUILD_PREFIX/bin/clang # links to emsdk clang

# rename flang-new binary to flang-new-bak
mv $BUILD_PREFIX/bin/flang-new $BUILD_PREFIX/bin/flang-new-bak

# copy flang-wrappers to bin
cp $RECIPE_DIR/flang_wrapper/flang-new     $BUILD_PREFIX/bin/
cp $RECIPE_DIR/flang_wrapper/flang-new.py  $BUILD_PREFIX/bin/








export FC=flang-new
export FFLAGS="-g --target=wasm32-unknown-emscripten"




# stderr: flang-new: error: unknown argument: '-s'
export LDFLAGS="-s SIDE_MODULE=1"
export CFLAGS=""
export CXXFLAGS=""
export FCFLAGS=""

# export FC_LD=wasm-ld






${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Csetup-args="-Dsystem-freetype=true" \
    -Csetup-args="-Dsystem-qhull=true" \
    -Csetup-args="-Dmacosx=false" \
    -C setup-args="-Dblas=blas" \
    -C setup-args="-Dlapack=lapack" \
    -C setup-args="-Duse-pythran=false"
