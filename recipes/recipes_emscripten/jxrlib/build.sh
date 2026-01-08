cp $RECIPE_DIR/patches/CMakeLists.txt $SRC_DIR

mkdir build && cd build

cmake ${CMAKE_ARGS} -D CMAKE_INSTALL_PREFIX="$PREFIX" \
      -D CMAKE_BUILD_TYPE=Release \
      $SRC_DIR

make
make install

cp ./JxrEncApp.wasm $PREFIX/bin/
cp ./JxrDecApp.wasm $PREFIX/bin/
