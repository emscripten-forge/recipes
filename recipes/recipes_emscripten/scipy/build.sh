#!/bin/bash

set -e

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
    -fvisibility=default \ 
    "

export CXXFLAGS="
    -fexceptions \
    -fvisibility=default \
    "

export LDFLAGS="-L$PREFIX/lib \
    -s WASM_BIGINT \
    -s STACK_SIZE=5MB \
    -s ALLOW_MEMORY_GROWTH=1 \
    -s EXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings,TTY \
    -s FORCE_FILESYSTEM=1 \
    -s INVOKE_RUN=0 \
    -s MODULARIZE=1
    -L$(NUMPY_LIB)/core/lib/ \ 
    -L$(NUMPY_LIB)/random/lib/ \
    -fexceptions"

export BACKEND_FLAGS="
    -build-dir=build \
    "

#   FC          Fortran compiler command
export FC=flang-new
#   FCFLAGS     Fortran compiler flags
export FCFLAGS="$FFLAGS --target=wasm32-unknown-emscripten"


export NPY_BLAS_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
export NPY_LAPACK_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"

sed -i '' 's/void DQA/int DQA/g' scipy/integrate/__quadpack.h

# Change many functions that return void into functions that return int
find scipy -name "*.c*" -type f | xargs sed -i '' 's/extern void F_FUNC/extern int F_FUNC/g'

sed -i '' 's/void F_FUNC/int F_FUNC/g' scipy/odr/__odrpack.c
sed -i '' 's/^void/int/g' scipy/odr/odrpack.h
sed -i '' 's/^void/int/g' scipy/odr/__odrpack.c

sed -i '' 's/void BLAS_FUNC/int BLAS_FUNC/g' scipy/special/lapack_defs.h
# sed -i 's/void F_FUNC/int F_FUNC/g' scipy/linalg/_lapack_subroutines.h
sed -i '' 's/extern void/extern int/g' scipy/optimize/__minpack.h
sed -i '' 's/void/int/g' scipy/linalg/cython_blas_signatures.txt
sed -i '' 's/void/int/g' scipy/linalg/cython_lapack_signatures.txt
sed -i '' 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c

sed -i '' 's/extern void/extern int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i '' 's/PUBLIC void/PUBLIC int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i '' 's/^void/int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i '' 's/^void/int/g' scipy/sparse/linalg/_dsolve/*.{c,h}
sed -i '' 's/void \(.\)print/int \1/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i '' 's/TYPE_GENERIC_FUNC(\(.*\), void)/TYPE_GENERIC_FUNC(\1, int)/g' scipy/sparse/linalg/_dsolve/_superluobject.h

sed -i '' 's/^void/int/g' scipy/optimize/_trlib/trlib_private.h
sed -i '' 's/^void/int/g' scipy/optimize/_trlib/trlib/trlib_private.h
sed -i '' 's/^void/int/g' scipy/_build_utils/src/wrap_dummy_g77_abi.c
sed -i '' 's/, int)/)/g' scipy/optimize/_trlib/trlib_private.h
sed -i '' 's/, 1)/)/g' scipy/optimize/_trlib/trlib_private.h

sed -i '' 's/^void/int/g' scipy/spatial/qhull_misc.h
sed -i '' 's/, size_t)/)/g' scipy/spatial/qhull_misc.h
sed -i '' 's/,1)/)/g' scipy/spatial/qhull_misc.h

# Input error causes "duplicate symbol" linker errors. Empty out the file.
echo "" > scipy/sparse/linalg/_dsolve/SuperLU/SRC/input_error.c

$PYTHON -m build