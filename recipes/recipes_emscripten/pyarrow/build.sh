#!/bin/bash


# rm  $SRC_DIR/cpp/cmake_modules/FindPython3Alt.cmake
# # rm  $SRC_DIR/cpp/cmake_modules/FindPythonLibsNew.cmake


# cp $RECIPE_DIR/setup.py $SRC_DIR/python/
# cp $RECIPE_DIR/CMakeLists.txt $SRC_DIR/python/
# # cp $RECIPE_DIR/FindPythonLibsNew.cmake $SRC_DIR/cpp/cmake_modules/
# cp $RECIPE_DIR/FindPython3Alt.cmake $SRC_DIR/cpp/cmake_modules/
# cp $RECIPE_DIR/SetupCxxFlags.cmake $SRC_DIR/cpp/cmake_modules/

PYARROW_CMAKE_OPTIONS=""
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPython3_INCLUDE_DIR=$PREFIX/include/python3.13"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPython3_INCLUDE_DIRS=$PREFIX/include/python3.13"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPython3_NumPy_INCLUDE_DIR=$BUILD_PREFIX/lib/python3.13/site-packages/numpy/_core/include"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPython3_NumPy_INCLUDE_DIRS=$BUILD_PREFIX/lib/python3.13/site-packages/numpy/_core/include"
# PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPython3_EXECUTABLE=$BUILD_PREFIX/bin/python -DPython3_INTERPRETER=$BUILD_PREFIX/bin/python"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_SIMD_LEVEL=None"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DArrow_DIR=$PREFIX/lib/cmake/Arrow"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DArrowDataset_DIR=$PREFIX/lib/cmake/ArrowDataset"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DArrowCompute_DIR=$PREFIX/lib/cmake/ArrowCompute"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dre2_DIR=$PREFIX/lib/cmake/re2"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dutf8proc_LIB=$PREFIX/lib/libutf8proc.a"
#  absl_DIR
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dabsl_DIR=$PREFIX/lib/cmake/absl"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dutf8proc_INCLUDE_DIR=$PREFIX/include"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_BUILD_SHARED=OFF"
# Disable SO versioning for emscripten - WASM can't handle versioned symlinks
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DCMAKE_PLATFORM_NO_VERSIONED_SONAME=TRUE"

PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_CUDA=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_DATASET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_FLIGHT=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_GANDIVA=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_ORC=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_PARQUET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_CSV=OFF"

PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_WITH_COMPUTE=ON"

PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_BUILD_SUBSTRAIT=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_BUILD_DATASET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_BUILD_PARQUET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_BUILD_ACERO=OFF"

PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_SUBSTRAIT=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_DATASET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_PARQUET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_ACERO=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPYARROW_PARQUET=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_ACERO=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_SUBSTRAIT=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_AZURE=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_GCS=OFF"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DPARQUET_REQUIRE_ENCRYPTION=OFF"

# disable acero

export PYARROW_CMAKE_OPTIONS
export _PYTHON_SYSCONFIGDATA_NAME="_sysconfigdata__emscripten_wasm32-emscripten"

# the python version
echo "PY_VER IS $PY_VER"

# we need to preted we are pyodide
export PYODIDE=1
export PYTHONINCLUDE=$PREFIX/include/python$PY_VER
export CPYTHONLIB=$PREFIX/lib/libpython$PY_VER.a

# cross-python will copy the python lib to the build prefix
export NUMPY_LIB="$PREFIX/lib/python$PY_VER/site-packages/numpy"
export SYSCONFIG_NAME="_sysconfigdata__emscripten_wasm32-emscripten"
export ARROW_HOME=$PREFIX
export INCLUDE_NUMPY_FLAGS="-I$BUILD_PREFIX/lib/python3.13/site-packages/numpy/core/include   -I$PREFIX/lib/python3.13/site-packages/numpy/core/include"
export CFLAGS="$CFLAGS $INCLUDE_NUMPY_FLAGS"
export CXXFLAGS="$CXXFLAGS $INCLUDE_NUMPY_FLAGS"
export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -s -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -s  -fexceptions"
# Use --whole-archive to ensure all symbols from Arrow static libraries are included
# This prevents symbols like DefaultDeviceMemoryMapper from being stripped
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -s -fexceptions"

export CMAKE_BUILD_PARALLEL_LEVEL=4

cd python

echo 'PYTHON $PYTHON'
$PREFIX/bin/python -c "import sys; print(sys.platform);print(sys.executable)"

# echo "PYTHON IS $PYTHON ${PYTHON}"
${PYTHON} -m pip install . -vvv
#  --platform wasm32-emscripten
SP=$PREFIX/lib/python3.13/site-packages/

# Copy libarrow_python.so to $PREFIX/lib so it can be found as a dependency by WASM side modules
# The Cython extensions (_compute.so, lib.so, etc.) depend on libarrow_python.so
cp "$SP/pyarrow/libarrow_python.so" "$PREFIX/lib/libarrow_python.so"

rm -rf $PREFIX/pyarrow/tests
rm -rf $PREFIX/pyarrow/_pyarrow_cpp_tests.cpython-313-wasm32-emscripten.so
rm -rf $PREFIX/pyarrow/__pycache__/

rm  -f $PREFIX/pyarrow/_compute.pyx
rm  -f $PREFIX/pyarrow/_compute_docstrings.py
rm  -f  $PREFIX/pyarrow/_csv.cpython-313-wasm32-emscripten.so
rm  -f  $PREFIX/pyarrow/_csv.pxd
rm  -f  $PREFIX/pyarrow/_csv.pyx
rm  -f  $PREFIX/pyarrow/_cuda.pxd
rm  -f  $PREFIX/pyarrow/_cuda.pyx
rm  -f  $PREFIX/pyarrow/_dataset.pxd
rm  -f  $PREFIX/pyarrow/_dataset.pyx
rm  -f  $PREFIX/pyarrow/_dataset_orc.pyx
rm  -f  $PREFIX/pyarrow/_dataset_parquet.pxd
rm  -f  $PREFIX/pyarrow/_dataset_parquet.pyx
rm  -f  $PREFIX/pyarrow/_dataset_parquet_encryption.pyx
rm  -f  $PREFIX/pyarrow/_dlpack.pxi
rm  -f  $PREFIX/pyarrow/_feather.cpython-313-wasm32-emscripten.so
rm  -f  $PREFIX/pyarrow/_feather.pyx
rm  -f  $PREFIX/pyarrow/_flight.pyx
rm  -f  $PREFIX/pyarrow/_fs.cpython-313-wasm32-emscripten.so
rm  -f  $PREFIX/pyarrow/_fs.pxd
rm  -f  $PREFIX/pyarrow/_fs.pyx
rm  -f  $PREFIX/pyarrow/_gcsfs.pyx
rm  -f  $PREFIX/pyarrow/_generated_version.py
rm  -f  $PREFIX/pyarrow/_hdfs.pyx

cd $PREFIX
find . -name "*.pyc" -exec rm -f {} \;