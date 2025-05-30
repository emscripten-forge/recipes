
mkdir build
cd build

# Configure step
emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \
    ..

# Build step
emmake make -j8 install
