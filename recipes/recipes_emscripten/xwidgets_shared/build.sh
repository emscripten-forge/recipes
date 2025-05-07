mkdir build
cd build

# Configure step
emcmake cmake       \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DXWIDGETS_BUILD_SHARED_LIBS=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_FIND_ROOT_PATH=$PREFIX \ 
    ..

# Build step
emmake make -j8 install