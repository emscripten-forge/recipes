#!/bin/bash


SIDE_PATH=$PREFIX/lib/python$PY_VER/site-packages
KERNEL_DIR=$PREFIX/share/jupyter/kernels/xeus_shakespearelang

mkdir build
cd build

# remove all the fake pythons
rm -f $PREFIX/bin/python*


export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

echo "PYTHON VER" $PY_VER

# Configure step    
cmake ${CMAKE_ARGS} ..                                      \
    -GNinja                                                 \
    -DCMAKE_BUILD_TYPE=Release                              \
    -DCMAKE_PREFIX_PATH=$PREFIX                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                          \
    -DXEUS_PYWRAP_INSTALL_XEUS_ECHO_KERNEL=OFF              \
    -DXEUS_PYWRAP_INSTALL_XEUS_SHAKESPEARELANG_KERNEL=ON    \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages \
    -DPython_INCLUDE_DIRS=$PREFIX/include/python${PY_VER} \
    -DPython_LIBRARY=$PREFIX/lib/libpython${PY_VER}.a \
    -DPython_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a \
    -DPython_Interpreter_FOUND=TRUE \
    -DPython_EXECUTABLE=$BUILD_PREFIX/bin/python${PY_VER} \
    -DPYTHON_MODULE_EXTENSION=.so \
    -DPYTHON_MODULE_DEBUG_POSTFIX="" \
    -DPYTHON_MODULE_EXT_SUFFIX=.so \
    -DPython_FOUND=TRUE \
    -DXEUS_PYWRAP_PYTHON_SITEARCH=$PREFIX/lib/python$PY_VER/site-packages



# Build step
ninja

ninja install

# remove raw-kernel
rm -rf $PREFIX/lib/python$PY_VER/site-packages/xpywrap
rm -rf $PREFIX/bin/xpywrap
rm -rf $PREFIX/lib/cmake/xeus-pywrap/


# show content of $PREFIX/share/jupyter/kernels/xeus_shakespearelang/kernel.json

cat $PREFIX/share/jupyter/kernels/xeus_shakespearelang/kernel.json