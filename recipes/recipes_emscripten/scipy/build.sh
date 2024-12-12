#!/bin/bash

set -e

mkdir -p build

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

export LDFLAGS="-Wl,-O2 -Wl,--sort-common -Wl,--as-needed -Wl,-z,relro -Wl,-z,now -Wl,--disable-new-dtags -Wl,--gc-sections -Wl,--allow-shlib-undefined \
    -Wl,-rpath,$PREFIX/lib -Wl,-rpath-link,$PREFIX/lib -L$PREFIX/lib"


#   LIBS        libraries to pass to the linker, e.g. -l<library>
export LIBS=" $LIBS \
    -lFortranRuntime" # NOTE: Needed for external blas and lapack

#   FC          Fortran compiler command
export FC=flang-new
#   FCFLAGS     Fortran compiler flags
export FCFLAGS="$FFLAGS --target=wasm32-unknown-emscripten"


#   PKG_CONFIG  path to pkg-config (or pkgconf) utility
export PKG_CONFIG=${BUILD_PREFIX}/bin/pkg-config
#   PKG_CONFIG_PATH directories to add to pkg-config's search path
export PKG_CONFIG_PATH=$PREFIX/lib/pkgconfig
#   PKG_CONFIG_LIBDIR path overriding pkg-config's default search path
export PKG_CONFIG_LIBDIR=$PREFIX/lib

export MESON_ARGS="--buildtype debug --prefix=$PREFIX -Dlibdir=lib"

# we write to the cross file here so that we can add paths dynamically
# https://docs.scipy.org/doc/scipy/building/cross_compilation.html
cp $RECIPE_DIR/emscripten.meson.cross $SRC_DIR
echo "python = '$BUILD_PREFIX/bin/python3.11'" >> $SRC_DIR/emscripten.meson.cross
echo -e "[constants]\nsitepkg = '$PREFIX/lib/python3.11/site-packages/'\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "[properties]\nneeds_exe_wrapper = true\nskip_sanity_check = true\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "longdouble_format= 'IEEE_QUAD_LE'\nnumpy-include-dir = sitepkg + 'numpy/core/include'\n" >> $SRC_DIR/emscripten.meson.cross
echo -e "pythran-include-dir = sitepkg + 'pythran'" >> $SRC_DIR/emscripten.meson.cross

cat $SRC_DIR/emscripten.meson.cross

# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
run_build() {
    $PYTHON -m build -w -n -x -v \
    -Cbuilddir=build \
    -Cinstall-args=--tags=runtime,python-runtime,devel \
    -Csetup-args=-Dbuildtype=debug \
    -Csetup-args=-Dblas=blas \
    -Csetup-args=-Dlapack=lapack \
    -Csetup-args=-Dfortran_std=none \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross" \
    -Ccompile-args="-j1" \
    -Ccompile-args="-v" 
}

if ! run_build; then
    cat $SRC_DIR/build/meson-logs/meson-log.txt
    exit 1
fi