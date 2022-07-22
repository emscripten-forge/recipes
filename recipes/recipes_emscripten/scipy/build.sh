# We get linker errors because the following 36 functions are missing
# Copying them from a more recent LAPACK seems to work fine.

wget https://github.com/Reference-LAPACK/lapack/archive/refs/tags/v3.10.0.tar.gz
tar xzf v3.10.0.tar.gz
cd lapack-3.10.0/SRC
cat \
    cgemqrt.f cgeqrfp.f cgeqrt.f clahqr.f csyconv.f csyconvf.f csyconvf_rook.f ctpmqrt.f ctpqrt.f cuncsd.f \
    dgemqrt.f dgeqrfp.f dgeqrt.f dlahqr.f dsyconv.f dsyconvf.f dsyconvf_rook.f dtpmqrt.f dtpqrt.f dorcsd.f \
    sgemqrt.f sgeqrfp.f sgeqrt.f slahqr.f ssyconv.f ssyconvf.f ssyconvf_rook.f stpmqrt.f stpqrt.f sorcsd.f \
    zgemqrt.f zgeqrfp.f zgeqrt.f zlahqr.f zsyconv.f zsyconvf.f zsyconvf_rook.f ztpmqrt.f ztpqrt.f zuncsd.f \
>>  ../../scipy/linalg/lapack_extras.f
sed -i 's/CHARACTER/INTEGER/g' ../../scipy/linalg/lapack_extras.f
sed -i 's/RECURSIVE//g' ../../scipy/linalg/lapack_extras.f
cd ../..
# Change many functions that return void into functions that return int
find scipy -name "*.c*" | xargs sed -i 's/extern void F_FUNC/extern int F_FUNC/g'
sed -i 's/void F_FUNC/int F_FUNC/g' scipy/odr/__odrpack.c
sed -i 's/^void/int/g' scipy/odr/odrpack.h
sed -i 's/^void/int/g' scipy/odr/__odrpack.c
sed -i 's/void BLAS_FUNC/int BLAS_FUNC/g' scipy/special/lapack_defs.h
# sed -i 's/void F_FUNC/int F_FUNC/g' scipy/linalg/_lapack_subroutines.h
sed -i 's/extern void/extern int/g' scipy/optimize/__minpack.h
sed -i 's/void/int/g' scipy/linalg/cython_blas_signatures.txt
sed -i 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c
sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/optimize/_trlib/trlib/trlib_private.h
sed -i 's/, int)/)/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/, 1)/)/g' scipy/optimize/_trlib/trlib_private.h
sed -i 's/^void/int/g' scipy/spatial/qhull_misc.h
sed -i 's/, size_t)/)/g' scipy/spatial/qhull_misc.h
sed -i 's/,1)/)/g' scipy/spatial/qhull_misc.h
# Missing declaration from cython_lapack_signatures.txt
echo "void ilaenv(int *ispec, char *name, char *opts, int *n1, int *n2, int *n3, int *n4)" \
    >>  scipy/linalg/cython_lapack_signatures.txt
# sed -i 's/^void/int/g' scipy/linalg/cython_lapack_signatures.txt
# Input error causes "duplicate symbol" linker errors. Empty out the file.
echo "" > scipy/sparse/linalg/_dsolve/SuperLU/SRC/input_error.c

# TODO this should be part of the clapack package!
wget https://netlib.org/clapack/clapack.h -O $PREFIX/include/clapack.h

# install f2c / emcc wrapper script
cp $RECIPE_DIR/FORTRAN.py $BUILD_PREFIX/bin/gfortran
chmod u+x $BUILD_PREFIX/bin/gfortran

# add BUILD_PREFIX/include for f2c.h file
export CFLAGS="$CFLAGS -I$BUILD_PREFIX/include"

python -m pip install . --no-deps -vv
