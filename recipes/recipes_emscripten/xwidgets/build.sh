
mkdir build
cd build

# Configure step
emcmake cmake       \
  -DCMAKE_BUILD_TYPE=Release     \
  -DCMAKE_PREFIX_PATH=$PREFIX   \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DXWIDGETS_BUILD_SHARED_LIBS=OFF \
  -DXWIDGETS_BUILD_STATIC_LIBS=ON \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  ..

emcc libxwidgets.a $EM_FORGE_SIDE_MODULE_LDFLAGS -o libxwidgets.so

# Build & Install step
emmake make -j8 install

cp libxwidgets.so $PREFIX/lib/
