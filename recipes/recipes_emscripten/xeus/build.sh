
mkdir build
cd build

# Configure step
emcmake cmake .. \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    -DXEUS_BUILD_SHARED_LIBS=ON \
    -DXEUS_BUILD_STATIC_LIBS=ON

# Build & Install step
emmake make -j8 install
