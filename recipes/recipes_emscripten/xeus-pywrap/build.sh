mkdir build
cd build

# remove all the fake pythons
rm -f $PREFIX/bin/python*


export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX


# Configure step    
cmake ${CMAKE_ARGS} ..                                      \
    -GNinja                                                 \
    -DCMAKE_BUILD_TYPE=Release                              \
    -DCMAKE_PREFIX_PATH=$PREFIX                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                          \
    -DXEUS_PYWRAP_INSTALL_XEUS_ECHO_KERNEL=OFF              \
    -DXEUS_PYWRAP_INSTALL_XEUS_SHAKESPEARELANG_KERNEL=ON    \
    -DPython_INCLUDE_DIR=$PREFIX/include/python${PY_VER} \
    -DPYTHONLIBS_FOUND=TRUE \
    -DPYTHON_LIBRARIES=$PREFIX/lib/libpython${PY_VER}.a \
    -DPYTHON_INCLUDE_DIRS=$PREFIX/include/python${PY_VER} \
    -DPYTHON_SITE_PACKAGES=$PREFIX/lib/python${PY_VER}/site-packages \
    -DXEUS_PYWRAP_PYTHON_SITEARCH=$PREFIX/lib/python$PYVER/site-packages


# Build step
ninja

ninja install

# remove raw-kernel
rm -rf $PREFIX/share/jupyter/kernels/xpython-raw/

