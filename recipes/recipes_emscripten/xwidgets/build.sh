
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DXWIDGETS_BUILD_SHARED_LIBS=OFF \
    -DXWIDGETS_BUILD_STATIC_LIBS=ON  \

# Build step
ninja install
