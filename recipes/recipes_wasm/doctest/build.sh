
mkdir build
cd build


# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_DEBUG_MODE=OFF \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DDOCTEST_WITH_TESTS=OFF \
    -DDOCTEST_WITH_MAIN_IN_STATIC_LIB=OFF 


# Build step
ninja install
