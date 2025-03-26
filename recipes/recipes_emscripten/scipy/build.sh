export F2C_PATH=$BUILD_PREFIX/bin/f2c

echo F2C_PATH: $F2C_PATH
export NPY_BLAS_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"
export NPY_LAPACK_LIBS="-I$PREFIX/include $PREFIX/lib/libopenblas.so"





# sed -i '/, thread_dep, atomic_dep/d' scipy/optimize/_highspy/meson.build
#                                      scipy/optimize/_highspy/meson.build

# sed -i '/thread_dep/d'              scipy/fft/_pocketfft/meson.build
# sed -i '/, thread_dep/d'            scipy/stats/meson.build

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
sed -i 's/^void/int/g' scipy/interpolate/src/_fitpackmodule.c

sed -i 's/double z_abs(/double my_z_abs(/g' scipy/sparse/linalg/_dsolve/SuperLU/SRC/dcomplex.c

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


sed -i '/char chla_transtype(int \*trans)/d' scipy/linalg/cython_lapack_signatures.txt

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
export CFLAGS="$CFLAGS -I$BUILD_PREFIX/include -Wno-return-type -DUNDERSCORE_G77 -s WASM_BIGINT"
export LDFLAGS="$LDFLAGS -s WASM_BIGINT"




#############################################################
# write out the cross file
#############################################################
export NUMPY_INCLUDE_DIR="$BUILD_PREFIX/lib/python${PY_VER}/site-packages/numpy/_core/include"
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
