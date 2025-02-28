#!/bin/bash


rm  $SRC_DIR/cpp/cmake_modules/FindPython3Alt.cmake
# rm  $SRC_DIR/cpp/cmake_modules/FindPythonLibsNew.cmake


cp $RECIPE_DIR/setup.py $SRC_DIR/python/
cp $RECIPE_DIR/CMakeLists.txt $SRC_DIR/python/
# cp $RECIPE_DIR/FindPythonLibsNew.cmake $SRC_DIR/cpp/cmake_modules/
cp $RECIPE_DIR/FindPython3Alt.cmake $SRC_DIR/cpp/cmake_modules/
cp $RECIPE_DIR/SetupCxxFlags.cmake $SRC_DIR/cpp/cmake_modules/

rm  -rf $PREFIX/bin/python*

# create symlink from $BUILD_PREFIX/bin/python3 to $PREFIX/bin/python
ln -s $BUILD_PREFIX/bin/python3 $PREFIX/bin/python

PYARROW_CMAKE_OPTIONS="-DPython3_INCLUDE_DIRS=$PREFIX/include/python3.13  -DPython3_NumPy_INCLUDE_DIRS=$PREFIX/lib/python3.13/site-packages/numpy/core/include -DPython3_EXECUTABLE=$BUILD_PREFIX/bin/python3 -DPython3_INTERPRETER=$BUILD_PREFIX/bin/python3"
PYARROW_CMAKE_OPTIONS="$PYARROW_CMAKE_OPTIONS -DARROW_SIMD_LEVEL=None"









export ARROW_HOME=$PREFIX
export PARQUET_HOME=$PREFIX
export PYARROW_WITH_ACERO=0
export PYARROW_WITH_AZURE=0
export PYARROW_WITH_DATASET=0
export PYARROW_WITH_FLIGHT=0
export PYARROW_WITH_GANDIVA=0
export PYARROW_WITH_GCS=0
export PYARROW_WITH_HDFS=0
export PYARROW_WITH_ORC=0
export PYARROW_WITH_PARQUET=0
export PYARROW_WITH_PARQUET_ENCRYPTION=0
export PYARROW_WITH_S3=0
export PYARROW_WITH_SUBSTRAIT=0


export INCLUDE_NUMPY_FLAGS="-I$BUILD_PREFIX/lib/python3.13/site-packages/numpy/core/include   -I$PREFIX/lib/python3.13/site-packages/numpy/core/include" 

export CFLAGS="$CFLAGS $INCLUDE_NUMPY_FLAGS"
export CXXFLAGS="$CXXFLAGS $INCLUDE_NUMPY_FLAGS"


export CFLAGS="$CFLAGS -sWASM_BIGINT"
export CXXFLAGS="$CXXFLAGS -sWASM_BIGINT"
export LDFLAGS="$LDFLAGS -sWASM_BIGINT"

cd python
${PYTHON} -m pip install . -vvv 

# INIT_PATH=$PREFIX/lib/python3.11/site-packages/pyarrow/__init__.py

# sed -i "s/__version__ = None/__version__ = \"$PKG_VERSION\"/g" $INIT_PATH