
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DXVEGA_DISABLE_ARCH_NATIVE=ON \
    -DXVEGA_BUILD_SHARED=OFF \
    -DXVEGA_BUILD_STATIC=ON \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON 

# Build step
ninja install
