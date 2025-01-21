
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_EXAMPLES=OFF           \
    -WITH_PIC=ON                   \
    -DPLATFORM=Web                 

# Build step
ninja install
