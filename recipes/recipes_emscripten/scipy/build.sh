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

export CFLAGS="-I$PREFIX/include \ 
    -Wno-return-type \ 
    -DUNDERSCORE_G77 \ 
    -fvisibility=default"

#export CXXFLAGS="
#    -fexceptions \
#    -fvisibility=default \
#    "

#export NUMPY_LIB=${BUILD_PREFIX}/lib/python${PYVERSION}/site-packages/numpy

export LDFLAGS="-L$PREFIX/lib"

export DYLIB_LDFLAGS="-sSIDE_MODULE"

#export BACKEND_FLAGS="
#    -build-dir=build \
#    "

#   LIBS        libraries to pass to the linker, e.g. -l<library>
export LIBS="-lFortranRuntime" # NOTE: Needed for external blas and lapack

#   FC          Fortran compiler command
export FC=flang-new
#   FCFLAGS     Fortran compiler flags
export FCFLAGS="$FFLAGS --target=wasm32-unknown-emscripten"


export NPY_BLAS_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
export NPY_LAPACK_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"

sed -i 's/void DQA/int DQA/g' scipy/integrate/__quadpack.h

# Change many functions that return void into functions that return int
find scipy -name "*.c*" -type f | xargs sed -i 's/extern void F_FUNC/extern int F_FUNC/g'

sed -i 's/void F_FUNC/int F_FUNC/g' scipy/odr/__odrpack.c
sed -i 's/^void/int/g' scipy/odr/odrpack.h
sed -i 's/^void/int/g' scipy/odr/__odrpack.c

sed -i 's/void BLAS_FUNC/int BLAS_FUNC/g' scipy/special/lapack_defs.h
# sed -i 's/void F_FUNC/int F_FUNC/g' scipy/linalg/_lapack_subroutines.h
sed -i 's/extern void/extern int/g' scipy/optimize/__minpack.h
sed -i 's/void/int/g' scipy/linalg/cython_blas_signatures.txt
sed -i 's/void/int/g' scipy/linalg/cython_lapack_signatures.txt
sed -i 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c

sed -i 's/extern void/extern int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/PUBLIC void/PUBLIC int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/^void/int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/^void/int/g' scipy/sparse/linalg/_dsolve/*.{c,h}
sed -i 's/void \(.\)print/int \1/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/TYPE_GENERIC_FUNC(\(.*\), void)/TYPE_GENERIC_FUNC(\1, int)/g' scipy/sparse/linalg/_dsolve/_superluobject.h

sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/_build_utils/src/wrap_dummy_g77_abi.c
sed -i 's/, int)/)/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/, 1)/)/g' scipy/optimize/_trlib/trlib_private.h

sed -i 's/^void/int/g' scipy/spatial/qhull_misc.h
sed -i 's/, size_t)/)/g' scipy/spatial/qhull_misc.h
sed -i 's/,1)/)/g' scipy/spatial/qhull_misc.h

# Input error causes "duplicate symbol" linker errors. Empty out the file.
echo "" > scipy/sparse/linalg/_dsolve/SuperLU/SRC/input_error.c

#${PYTHON} -m pip install . --no-build-isolation

# meson-python already sets up a -Dbuildtype=release argument to meson, so
# we need to strip --buildtype out of MESON_ARGS or fail due to redundancy
MESON_ARGS_REDUCED="$(echo $MESON_ARGS | sed 's/--buildtype release //g')"

# -wnx flags mean: --wheel --no-isolation --skip-dependency-check
$PYTHON -m build -w -n -x \
    -Cbuilddir=build \
    -Cinstall-args=--tags=runtime,python-runtime,devel \
    -Csetup-args=-Duse-g77-abi=true \
    -Csetup-args=-Dblas=blas \
    -Csetup-args=-Dfortran_std=none \
    -Csetup-args="--cross-file=$RECIPE_DIR/emscripten.meson.cross" 
#    || (cat $BUILD_PREFIX/build/meson-logs/meson-log.txt && exit 1)
#    -Csetup-args=${MESON_ARGS_REDUCED// / -Csetup-args=} \