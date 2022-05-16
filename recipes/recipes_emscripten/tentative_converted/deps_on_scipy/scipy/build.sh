#!/bin/bash

pip install scipy==1.7.3 pybind11[global] pythran
pip install --upgrade pybind11[global] pythran -t $PYODIDE_ROOT/packages/.artifacts/
# We get linker errors because the following 36 functions are missing
# Copying them from a more recent LAPACK seems to work fine.
wget https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.10.0.tar.gz
tar xzf v3.10.0.tar.gz
cd lapack-3.10.0/SRC
cat \
  cgemqrt.f cgeqrfp.f cgeqrt.f clahqr.f csyconv.f csyconvf.f csyconvf_rook.f ctpmqrt.f ctpqrt.f \
  dgemqrt.f dgeqrfp.f dgeqrt.f dlahqr.f dsyconv.f dsyconvf.f dsyconvf_rook.f dtpmqrt.f dtpqrt.f \
  sgemqrt.f sgeqrfp.f sgeqrt.f slahqr.f ssyconv.f ssyconvf.f ssyconvf_rook.f stpmqrt.f stpqrt.f \
  zgemqrt.f zgeqrfp.f zgeqrt.f zlahqr.f zsyconv.f zsyconvf.f zsyconvf_rook.f ztpmqrt.f ztpqrt.f \
>>  ../../scipy/linalg/lapack_extras.f
cd ../..
# The additional four functions cuncsd, dorcsd, sorcsd, and zuncsd are also
# missing but they use features of Fortran that aren't Fortran 77 compatible
# so f2c can't handle them. We stub them with C definitions that do nothing.
# These stubs come from f2cpatches/wrap_dummy_g77_abi.patch

# Change many functions that return void into functions that return int
find scipy -name "*.c*" | xargs sed -i 's/extern void F_FUNC/extern int F_FUNC/g'
sed -i 's/void F_FUNC/int F_FUNC/g' scipy/odr/__odrpack.c
sed -i 's/extern void/extern int/g' scipy/optimize/__minpack.h
sed -i 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c
sed -i 's/void/int/g' scipy/linalg/cython_blas_signatures.txt

# Missing declaration from cython_lapack_signatures.txt
echo "void ilaenv(int *ispec, char *name, char *opts, int *n1, int *n2, int *n3, int *n4)" \
  >>  scipy/linalg/cython_lapack_signatures.txt

# Input error causes "duplicate symbol" linker errors. Empty out the file.
echo "" > scipy/sparse/linalg/dsolve/SuperLU/SRC/input_error.c
echo 'import sys' >> scipy/__init__.py
echo 'if "pyodide_js" in sys.modules:'  >> scipy/__init__.py
echo '   from pyodide_js._module import loadDynamicLibrary' >> scipy/__init__.py
echo "   loadDynamicLibrary('/lib/python$PYMAJOR.$PYMINOR/site-packages/scipy/linalg/_flapack.so')" >> scipy/__init__.py
