
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DXPLUGIN_BUILD_TESTS=OFF \
    -DXPLUGIN_BUILD_DOCS=OFF \
    -DXPLUGIN_BUILD_EXAMPLES=OFF \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_INSTALL_LIBDIR=lib \

# Build step
ninja install