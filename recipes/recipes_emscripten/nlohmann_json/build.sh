
mkdir build
cd build


# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DJSON_BuildTests=OFF          \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \

# Build step
ninja install
