mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

export PYTHON_LIBRARIES=$PREFIX/lib/libpython3.13.a
export PYTHON_INCLUDE_DIR=$PREFIX/include/python3.13


nanobind_DIR=$($PYTHON -m nanobind --cmake_dir)
echo "nanobind_DIR: $nanobind_DIR"

ls $nanobind_DIR

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DPython_EXECUTABLE=$PYTHON                     \
    -DPython_Interpreter=$PYTHON                     \
    -DPython_INCLUDE_DIRS=$PREFIX/include/python3.13 \
    -DPython_LIBRARY=$PREFIX/lib/libpython3.13.a \
    -DPython_LIBRARIES=$PREFIX/lib/libpython3.13.a \
    -DNB_SUFFIX="" \
    -DNB_SUFFIX_S="" \
    -DEXT_SUFFIX="so" \
    -Dnanobind_DIR=$nanobind_DIR


# Build step
ninja



# make python side-package pyb2d
mkdir -p $PREFIX/lib/python3.13/site-packages/pyb2d

# copy $SRC_DIR/src/module/pyb2d to $PREFIX/lib/python3.13/site-packages/pyb2d
cp -r $SRC_DIR/src/module/pyb2d $PREFIX/lib/python3.13/site-packages/

