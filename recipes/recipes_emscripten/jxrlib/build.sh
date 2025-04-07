#copy cmakelists from recipe to src


filename=image/decode/segdec.c


cp $RECIPE_DIR/CMakeLists.txt $SRC_DIR

mkdir build && cd build

cmake ${CMAKE_ARGS} -D CMAKE_INSTALL_PREFIX="$PREFIX" \
      -D CMAKE_BUILD_TYPE=Release \
      $SRC_DIR

make
make install