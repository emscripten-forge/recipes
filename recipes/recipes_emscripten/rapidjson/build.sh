
mkdir build
cd build


# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DRAPIDJSON_BUILD_DOC=OFF          \
    -DRAPIDJSON_BUILD_EXAMPLES=OFF          \
    -DRAPIDJSON_BUILD_TESTS=OFF          \
    -DCMAKE_INSTALL_PREFIX=$PREFIX 

# Build step
ninja install
