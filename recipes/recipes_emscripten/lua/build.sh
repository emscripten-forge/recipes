#!/usr/bin/env bash




echo "EMSCRIPTEN!"

mkdir build
cd build


# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DLUA_USER_DEFAULT_PATH=$PREFIX \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_C_FLAGS="-DLUA_USER_DEFAULT_PATH='\"$PREFIX/\"'" \

# Build step
ninja install
