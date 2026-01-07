export F2C_PATH=$BUILD_PREFIX/bin/f2c

set -ex

export CFLAGS="-I$PREFIX/include/python3.13 $CFLAGS"
export CXXFLAGS="-I$PREFIX/include/python3.13 $CXXFLAGS"

echo F2C_PATH: $F2C_PATH
export NPY_BLAS_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
export NPY_LAPACK_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"

sed -i '/char chla_transtype(int \*trans)/d' scipy/linalg/cython_lapack_signatures.txt
cat scipy/linalg/cython_lapack_signatures.txt


sed -i "s/dependency('threads', required: false)/dependency('', required: false)/g" scipy/meson.build
sed -i "s/dependency('atomic', required: false)/dependency('', required: false)/g" scipy/meson.build

cp $RECIPE_DIR/patches/scipy_config.in.h   scipy/scipy_config.h.in



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
sed -i 's/^void/int/g' scipy/linalg/_common_array_utils.h

sed -i 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c
sed -i 's/^void/int/g' scipy/interpolate/src/__fitpack.h
sed -i 's/^void/int/g' scipy/interpolate/src/__fitpack.cc
sed -i 's/void BLAS_FUNC/int BLAS_FUNC/g' scipy/interpolate/src/__fitpack.h

sed -i 's/double z_abs(/double my_z_abs(/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/dcomplex.c

sed -i 's/extern void/extern int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/PUBLIC void/PUBLIC int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/^void/int/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/^void/int/g' scipy/sparse/linalg/_dsolve/*.{c,h}
sed -i 's/void \(.\)print/int \1/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/*.{c,h}
sed -i 's/TYPE_GENERIC_FUNC(\(.*\), void)/TYPE_GENERIC_FUNC(\1, int)/g' scipy/sparse/linalg/_dsolve/_superluobject.h

sed -i 's/^void/int/g' scipy/optimize/__nnls.h
sed -i 's/^void/int/g' scipy/optimize/__nnls.c
sed -i 's/^void/int/g' scipy/optimize/__slsqp.h
sed -i 's/^void/int/g' scipy/optimize/__slsqp.c
sed -i 's/^static void/static int/g' scipy/optimize/__slsqp.c

sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/_build_utils/src/wrap_dummy_g77_abi.c
sed -i 's/, int)/)/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/, 1)/)/g' scipy/optimize/_trlib/trlib_private.h

sed -i 's/^void/int/g' scipy/linalg/_matfuncs_expm.h
sed -i 's/^void/int/g' scipy/linalg/_matfuncs_expm.c
sed -i 's/^void/int/g' scipy/linalg/_matfuncs_sqrtm.h
sed -i 's/^void/int/g' scipy/linalg/_matfuncs_sqrtm.c

sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_n_double_complex.h
sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_n_double.h
sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_n_single_complex.h
sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_n_single.h
sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_s_double.h
sed -i 's/^void/int/g' scipy/sparse/linalg/_eigen/arpack/ARPACK/_arpack_s_single.h

sed -i 's/^void/int/g' scipy/spatial/qhull_misc.h
sed -i 's/^void/int/g' scipy/optimize/__lbfgsb.h
sed -i 's/, size_t)/)/g' scipy/spatial/qhull_misc.h
sed -i 's/,1)/)/g' scipy/spatial/qhull_misc.h

# Input error causes "duplicate symbol" linker errors. Empty out the file.
echo "" > scipy/sparse/linalg/_dsolve/SuperLU/SRC/input_error.c

# https://github.com/mesonbuild/meson/blob/e542901af6e30865715d3c3c18f703910a096ec0/mesonbuild/backend/ninjabackend.py#L94
# Prevent from using response file. The response file that meson generates is not compatible to pyodide-build
export MESON_RSP_THRESHOLD=131072


# install f2c / emcc wrapper script
cp $RECIPE_DIR/patches/fortran_compiler_wrapper.py $BUILD_PREFIX/bin/gfortran
chmod u+x $BUILD_PREFIX/bin/gfortran
export FC=$BUILD_PREFIX/bin/gfortran


# Add pyodide scipy C file fixes to emcc
export EMBIN=$CONDA_EMSDK_DIR/upstream/emscripten
python $RECIPE_DIR/inject_compiler_wrapper.py $EMBIN/emcc.py

# add BUILD_PREFIX/include for f2c.h file
# Fix LONG_BIT issue: Python's pyport.h checks LONG_BIT and errors if it doesn't match expectations
# We need to patch pyport.h to undefine LONG_BIT before the check (same as Python recipe patch 0005)
if [ -f "$BUILD_PREFIX/include/python${PY_VER}/pyport.h" ]; then
  # Apply the same fix as Python recipe patch 0005: add #undef LONG_BIT before the check
  if ! grep -q "^#undef LONG_BIT" "$BUILD_PREFIX/include/python${PY_VER}/pyport.h"; then
    # Find the line with "#ifndef LONG_BIT" and add "#undef LONG_BIT" before it
    sed -i '/^#ifndef LONG_BIT/i#undef LONG_BIT' "$BUILD_PREFIX/include/python${PY_VER}/pyport.h"
  fi
fi
# Note: -s WASM_BIGINT is a linker flag, not a compiler flag
# Suppress incompatible function pointer type errors (due to void->int function changes)
# Set visibility=default for C++ symbols to fix "bad export type" errors (e.g., _ZTIPFvbE)
# NumPy 2.1+ disabled visibility for symbols outside of extension modules by default,
# so we need to explicitly set visibility=default for SciPy modules that rely on NumPy symbols
# Use single quotes around the entire macro definition to preserve the inner double quotes
# The quotes in NPY_API_SYMBOL_ATTRIBUTE will cause a syntax error in the generated __config__.py
# We'll fix this in the post-install step below
export CFLAGS="$CFLAGS -I$BUILD_PREFIX/include -Wno-return-type -DUNDERSCORE_G77 -Wno-incompatible-function-pointer-types -DNPY_API_SYMBOL_ATTRIBUTE='__attribute__((visibility(\"default\")))' -fvisibility=default"
export CXXFLAGS="$CXXFLAGS -Wno-incompatible-function-pointer-types -fvisibility=default"
# Add numpy library paths to LDFLAGS for linking
# Get numpy installation path using Python
NUMPY_LIB=$(python -c "import numpy; import os; print(os.path.dirname(numpy.__file__))")
# Build Python extension modules as side modules to ensure PyInit functions are exported
# SIDE_MODULE=1 is required for Python extension modules in Emscripten
# EXPORT_ALL=1 is required to export all symbols from the extension module (e.g. HiGHS)
export LDFLAGS="$LDFLAGS -s WASM_BIGINT -s EXPORT_ALL=1 -s SIDE_MODULE=1 -L${NUMPY_LIB}/_core/lib -L${NUMPY_LIB}/random/lib"




#############################################################
# write out the cross file
#############################################################
# Get numpy include directory using Python - resolve to actual filesystem path
NUMPY_INCLUDE_DIR=$(python -c "import numpy; import os; numpy_dir = os.path.dirname(numpy.__file__); include_dir = os.path.join(numpy_dir, '_core', 'include'); print(os.path.abspath(os.path.realpath(include_dir)))")
export NUMPY_INCLUDE_DIR
echo "NUMPY_INCLUDE_DIR=${NUMPY_INCLUDE_DIR}"
# Use | as delimiter for sed
sed "s|@(NUMPY_INCLUDE_DIR)|${NUMPY_INCLUDE_DIR}|g" $RECIPE_DIR/emscripten.meson.cross > $SRC_DIR/emscripten.meson.cross.temp
sed "s|@(PYTHON)|${PYTHON}|g" $SRC_DIR/emscripten.meson.cross.temp > $SRC_DIR/emscripten.meson.cross
rm $SRC_DIR/emscripten.meson.cross.temp
echo "THE CROSS FILE"
cat $SRC_DIR/emscripten.meson.cross
echo "END CROSS FILE"



export PKG_CONFIG_PATH=$SRC_DIR=openblas.pc


MESON_ARGS="-Dfortran_std=none" ${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$SRC_DIR/emscripten.meson.cross"\
    -Csetup-args="-Dfortran_std=none"

# Fix syntax error in generated __config__.py: escape quotes in NPY_API_SYMBOL_ATTRIBUTE
# Meson writes the CFLAGS to the config file, and the double quotes break Python syntax
# The config file is generated during build, so we need to find and fix it after pip install
# Look for __config__.py in the site-packages directory
if [ -d "$SP_DIR/scipy" ]; then
  SCIPY_CONFIG="$SP_DIR/scipy/__config__.py"
elif [ -n "$PREFIX" ] && [ -d "$PREFIX/lib/python${PY_VER}/site-packages/scipy" ] && [ -f "$PREFIX/lib/python${PY_VER}/site-packages/scipy/__config__.py" ]; then
  SCIPY_CONFIG="$PREFIX/lib/python${PY_VER}/site-packages/scipy/__config__.py"
else
  # Try to find it using Python
  SCIPY_CONFIG=$(python -c "import scipy; import os; print(os.path.join(os.path.dirname(scipy.__file__), '__config__.py'))" 2>/dev/null || echo "")
fi

if [ -n "$SCIPY_CONFIG" ] && [ -f "$SCIPY_CONFIG" ]; then
  echo "Fixing syntax error in $SCIPY_CONFIG"
  # Replace unescaped double quotes in the visibility("default") part with escaped quotes
  # This fixes: visibility("default") -> visibility(\"default\")
  # Need to escape both the quotes and the backslashes for sed
  sed -i 's/visibility("default")/visibility(\\"default\\")/g' "$SCIPY_CONFIG"
  echo "Fixed config file syntax"
else
  echo "Warning: Could not find scipy/__config__.py to fix syntax error"
  echo "Searched in: $SP_DIR/scipy, $PREFIX/lib/python${PY_VER}/site-packages/scipy, $SRC_DIR/scipy"
fi
