#!/bin/bash
# TODO: change the wasm_library_dir and numpy_lib variables
export CFLAGS="
    -I$(WASM_LIBRARY_DIR)/include \ 
    -Wno-return-type \ 
    -DUNDERSCORE_G77 \ 
    -fvisibility=default \ 
    "

export CXXFLAGS="
    -fexceptions \
    -fvisibility=default \
    "

export LDFLAGS="
    -L$(NUMPY_LIB)/core/lib/ \ 
    -L$(NUMPY_LIB)/random/lib/ \
    -fexceptions \ 
    "

export BACKEND_FLAGS="
    -build-dir=build \
    "

set -x
git clone https://github.com/hoodmane/f2c.git --depth 1
(cd f2c/src && cp makefile.u makefile && sed -i '' 's/gram.c:/gram.c1:/' makefile)
export F2C_PATH=$(BUILD_PREFIX)/f2c/src/f2c

echo F2C_PATH: $F2C_PATH
export NPY_BLAS_LIBS="-I$WASM_LIBRARY_DIR/include $WASM_LIBRARY_DIR/lib/libopenblas.so"
export NPY_LAPACK_LIBS="-I$WASM_LIBRARY_DIR/include $WASM_LIBRARY_DIR/lib/libopenblas.so"

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
