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

# Build stpe
emmake make -j8

emcc libxcanvas.a $EM_FORGE_SIDE_MODULE_LDFLAGS -o libxcanvas.so

# Install step
emmake make -j8 install

cp libxcanvas.so $PREFIX/lib/
