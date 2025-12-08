mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..                    \
    -GNinja                               \
    -DCMAKE_BUILD_TYPE=Release            \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX}    \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON

# Build step (install headers and cmake config files)
ninja install