#!/bin/bash

set -e

mkdir -p build

printenv

# Using flang as a WASM cross-compiler
# https://github.com/serge-sans-paille/llvm-project/blob/feature/flang-wasm/README.wasm.md
# https://github.com/conda-forge/flang-feedstock/pull/69
micromamba install -p $BUILD_PREFIX \
    conda-forge/label/llvm_rc::libllvm19=19.1.0.rc2 \
    conda-forge/label/llvm_dev::flang=19.1.0.rc2 \
    -y --no-channel-priority
rm $BUILD_PREFIX/bin/clang # links to clang19
ln -s $BUILD_PREFIX/bin/clang-18 $BUILD_PREFIX/bin/clang # links to emsdk clang


export CFLAGS="-mtune=haswell -ftree-vectorize -fPIC -fstack-protector-strong -fno-plt -O2 -ffunction-sections -pipe -isystem $PREFIX/include \
    -DUNDERSCORE_G77 -I$PREFIX/include" 
#    -Wno-return-type \ 
#    -fvisibility=default"

export CXXFLAGS="$CXXFLAGS \
    -fexceptions \
    -fvisibility=default"

#export NUMPY_LIB=${BUILD_PREFIX}/lib/python${PYVERSION}/site-packages/numpy

export LDFLAGS="-Wl,-O2 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections -Wl,--allow-shlib-undefined \
    -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib"

# empty LDFLAGS because of -sWASM_BIGINT
#export LDFLAGS="-L$PREFIX/lib"

#export DYLIB_LDFLAGS="-sSIDE_MODULE"

#export BACKEND_FLAGS="
#    -build-dir=build \
#    "

#   LIBS        libraries to pass to the linker, e.g. -l<library>
export LIBS=" $LIBS \
    -lFortranRuntime" # NOTE: Needed for external blas and lapack

#   FC          Fortran compiler command
export FC=flang-new
#   FCFLAGS     Fortran compiler flags
export FCFLAGS="$FFLAGS --target=wasm32-unknown-emscripten"


#export NPY_BLAS_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
#export NPY_LAPACK_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
#export PKG_CONFIG_PATH=/some/path...:$PKG_CONFIG_PATH
#   PKG_CONFIG  path to pkg-config (or pkgconf) utility
export PKG_CONFIG=${BUILD_PREFIX}/bin/pkg-config
#   PKG_CONFIG_PATH directories to add to pkg-config's search path
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
#   PKG_CONFIG_LIBDIR path overriding pkg-config's default search path
export PKG_CONFIG_LIBDIR=$PREFIX/lib

export MESON_ARGS="--buildtype debug --prefix=$PREFIX -Dlibdir=lib"

# https://docs.scipy.org/doc/scipy/building/cross_compilation.html#
#export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/core/include"
# we write the emscripten.meson.cross file mostly here to be able to include dynamic paths
cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo -e "python = '$PREFIX/bin/python3.11'\n" >> $SRC_DIR/emscripten.meson.cross #not sure if this should be host or build python (maybe change to $BUILD_PREFIX)
echo -e "[constants]\nsitepkg = '$PREFIX/lib/python3.11/site-packages/'\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "[properties]\nneeds_exe_wrapper = true\nskip_sanity_check = true\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "longdouble_format= 'IEEE_QUAD_LE'\nnumpy-include-dir = sitepkg + 'numpy/core/include'\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "pythran-include-dir = sitepkg + 'pythran'" >> $SRC_DIR/emscripten.meson.cross

cat $SRC_DIR/emscripten.meson.cross

# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
$PYTHON -m build -w -n -x -v \
    -Cbuilddir=build \
    -Cinstall-args=--tags=runtime,python-runtime,devel \
    -Csetup-args=-Dbuildtype=debug \
    -Csetup-args=-Dblas=blas \
    -Csetup-args=-Dlapack=lapack \
    -Csetup-args=-Dfortran_std=none \
    -Csetup-args="--cross-file=$RECIPE_DIR/emscripten.meson.cross" \
    -Ccompile-args="-j1" \
    -Ccompile-args="-v" 
#    -Csetup-args=-Duse-g77-abi=true \
#    || (cat $BUILD_PREFIX/build/meson-logs/meson-log.txt && exit 1)
#    -Csetup-args=${MESON_ARGS_REDUCED// / -Csetup-args=} \