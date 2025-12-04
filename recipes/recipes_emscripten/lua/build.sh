mkdir build
cd build



# Configure step
cmake ${CMAKE_ARGS} ..             \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DLUA_USER_DEFAULT_PATH=$PREFIX \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON \
    -DCMAKE_C_FLAGS="-DLUA_USER_DEFAULT_PATH='\"$PREFIX/\"'" \

# Build step
make -j${CPU_COUNT}

# Install step
make -j${CPU_COUNT} install
