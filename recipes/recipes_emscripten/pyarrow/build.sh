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
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dre2_DIR=$PREFIX/lib/cmake/re2"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dutf8proc_LIB=$PREFIX/lib/libutf8proc.a"
#  absl_DIR
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dabsl_DIR=$PREFIX/lib/cmake/absl"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -Dutf8proc_INCLUDE_DIR=$PREFIX/include"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_BUILD_SHARED=OFF"

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
# export PARQUET_HOME=$PREFIX
# export PYARROW_WITH_ACERO=0
# export PYARROW_WITH_AZURE=0
# export PYARROW_WITH_DATASET=0
# export PYARROW_WITH_FLIGHT=0
# export PYARROW_WITH_GANDIVA=0
# export PYARROW_WITH_GCS=0
# export PYARROW_WITH_HDFS=0
# export PYARROW_WITH_ORC=0
# export PYARROW_WITH_PARQUET=0
# export PYARROW_WITH_PARQUET_ENCRYPTION=0
# export PYARROW_WITH_S3=0
# export PYARROW_WITH_SUBSTRAIT=0


export INCLUDE_NUMPY_FLAGS="-I$BUILD_PREFIX/lib/python3.13/site-packages/numpy/core/include   -I$PREFIX/lib/python3.13/site-packages/numpy/core/include"

export CFLAGS="$CFLAGS $INCLUDE_NUMPY_FLAGS"
export CXXFLAGS="$CXXFLAGS $INCLUDE_NUMPY_FLAGS"


export CFLAGS="$CFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT -s SIDE_MODULE=1 -fexceptions"

export CMAKE_BUILD_PARALLEL_LEVEL=4

cd python


echo 'PYTHON $PYTHON'
$PREFIX/bin/python -c "import sys; print(sys.platform);print(sys.executable)"



#
# $PREFIX/bin/python -m pip install . -vvv  --platform wasm32-emscripten --target $PREFIX

# echo "PYTHON IS $PYTHON ${PYTHON}"
${PYTHON} -m pip install . -vvv
#  --platform wasm32-emscripten
SP=$PREFIX/lib/python3.13/site-packages/

rm -rf $PREFIX/pyarrow/tests
rm -rf $PREFIX/pyarrow/_pyarrow_cpp_tests.cpython-313-wasm32-emscripten.so
rm -rf $PREFIX/pyarrow/__pycache__/


 rm  -f $PREFIX/pyarrow/_compute.cpython-313-wasm32-emscripten.so
 rm  -f $PREFIX/pyarrow/_compute.pxd
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
#  rm  -f  $PREFIX/pyarrow/_json.cpython-313-wasm32-emscripten.so
#  rm  -f  $PREFIX/pyarrow/_json.pxd



cd $PREFIX
find . -name "*.pyc" -exec rm -f {} \;












# $PYTHON setup.py build_ext install --single-version-externally-managed \
#                 --record=record.txt

# PLAT_NAME=wasm32-emscripten
# export CFLAGS="$CFLAGS -target $PLAT_NAME"
# export CXXFLAGS="$CXXFLAGS -target $PLAT_NAME"
# export LDFLAGS="$LDFLAGS -target $PLAT_NAME"


# python setup.py build_ext --inplace --plat-name $PLAT_NAME
# INIT_PATH=$PREFIX/lib/python3.11/site-packages/pyarrow/__init__.py

# sed -i "s/__version__ = None/__version__ = \"$PKG_VERSION\"/g" $INIT_PATH
