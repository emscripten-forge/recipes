mkdir build
cd build

# Configure step
emcmake cmake ${CMAKE_ARGS} \
    -DCMAKE_PREFIX_PATH:PATH=${PREFIX} \
    -DCMAKE_INSTALL_PREFIX:PATH=${PREFIX} \
    -DCMAKE_INSTALL_LIBDIR=lib \
    -DCMAKE_BUILD_TYPE=Release \
    -DBUILD_SHARED_LIBS=OFF \
    -DBUILD_TESTS=OFF \
    -DWITH_OPENMP=OFF \
    -DWITH_LSR_BINDINGS=OFF \
    ../

# Build step
emmake make install -j${CPU_COUNT}