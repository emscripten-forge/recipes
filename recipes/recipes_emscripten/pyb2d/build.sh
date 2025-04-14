mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX


# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DPYTHON_NUMPY_INCLUDE_DIR="$PREFIX/lib/python3.11/site-packages/numpy/core/include" \
    -DPYTHON_MODULE_INSTALL_DIR="$PREFIX/lib/python3.11/site-packages" \
    -DPYB2D_LIQUID_FUN=ON
# Build step
ninja



ninja install
