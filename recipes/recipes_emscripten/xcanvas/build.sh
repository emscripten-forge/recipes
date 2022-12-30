
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..              \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DXCANVAS_BUILD_SHARED_LIBS=OFF \
    -DXCANVAS_BUILD_STATIC_LIBS=ON

# Build step
ninja install
