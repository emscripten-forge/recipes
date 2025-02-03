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
# flang-new: error: no such file or directory: 'SIDE_MODULE=1'
export LDFLAGS="--disable-shared"
export CFLAGS=""
export CXXFLAGS=""
export FCFLAGS=""

# export FC_LD=wasm-ld


mkdir builddir

meson_config_args=(
    -Dblas=blas
    -Dlapack=lapack
    -Duse-pythran=false
)

#try and in case of failure, print cat  $SRC_DIR/builddir/meson-logs/meson-log.txt
{
    meson setup builddir \
        "${meson_config_args[@]}" \
        --buildtype=release \
        --default-library=static \
        --prefer-static \
        --prefix=$PREFIX \
        --wrap-mode=nofallback \
        --cross-file=$SRC_DIR/emscripten.meson.cross

} || {
    cat  $SRC_DIR/builddir/meson-logs/meson-log.txt
    exit 1
}