
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
    -DUSE_SYSTEM_TZ_DB=ON -DBUILD_TZ_LIB=ON -DCMAKE_CXX_FLAGS="-fPIC"






# Build step
ninja install
