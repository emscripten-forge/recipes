cp $RECIPE_DIR/patches/CMakeLists.txt $SRC_DIR

# newer clang turns these legacy pointer casts into hard errors
export CFLAGS="${CFLAGS} -Wno-error=incompatible-pointer-types"

mkdir build && cd build

cmake ${CMAKE_ARGS} -D CMAKE_INSTALL_PREFIX="$PREFIX" \
      -D CMAKE_BUILD_TYPE=Release \
      -D CMAKE_POLICY_VERSION_MINIMUM=3.5 \
      $SRC_DIR

make
make install

cp ./JxrEncApp.wasm $PREFIX/bin/
cp ./JxrDecApp.wasm $PREFIX/bin/
