mkdir build && cd build

export CMAKE_ARGS="$CMAKE_ARGS -DCMAKE_PROJECT_INCLUDE=${RECIPE_DIR}/overwriteProp.cmake"

cmake $CMAKE_ARGS -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH=$PREFIX \
      -DCMAKE_INSTALL_PREFIX=$PREFIX \
      -DBUILD_SHARED_LIBS=ON \
      -DCMAKE_INSTALL_LIBDIR=lib \
      $SRC_DIR

make VERBOSE=1 -j${CPU_COUNT}
make install
