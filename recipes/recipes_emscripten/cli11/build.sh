mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} ..      \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCLI11_BUILD_TESTS=OFF \
    -DCLI11_BUILD_EXAMPLES=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib \
    ${CMAKE_ARGS} \
    -DCMAKE_PROJECT_INCLUDE=$RECIPE_DIR/overwriteProp.cmake

# Build step
ninja install
