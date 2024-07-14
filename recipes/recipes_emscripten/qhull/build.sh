mkdir build && cd build

cmake -GNinja $SRC_DIR $CMAKE_ARGS

ninja install