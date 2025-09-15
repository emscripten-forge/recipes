mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -GNinja                         \
    -DCMAKE_BUILD_TYPE=Release      \
    -DCMAKE_PREFIX_PATH=$PREFIX     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX  \
    -DZLIB_BUILD_EXAMPLES=OFF       \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_VERBOSE_MAKEFILE=ON     \
    -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake

# Build step
ninja -v install
