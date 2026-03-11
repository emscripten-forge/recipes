
mkdir build
cd build

# Configure step
emcmake cmake       \
  -DCMAKE_BUILD_TYPE=Release     \
  -DCMAKE_PREFIX_PATH="$PREFIX;$PREFIX/lib/cmake;$PREFIX/share/cmake" \
  -DCMAKE_INSTALL_PREFIX=$PREFIX \
  -DCMAKE_FIND_ROOT_PATH=$PREFIX \
  ..

# Build & Install step
emmake make -j8 install
