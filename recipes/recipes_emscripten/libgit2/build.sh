mkdir build
cd build

cmake ${CMAKE_ARGS} .. \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DBUILD_EXAMPLES=OFF \
    -DUSE_HTTPS=OFF \
    -DUSE_THREADS=OFF

ninja install

# Install .wasm files as well
cp git2.wasm ${PREFIX}/bin
