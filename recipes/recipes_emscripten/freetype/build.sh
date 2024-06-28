mkdir build && cd build

emcmake cmake .. $CMAKE_ARGS

make install -j${CPU_COUNT}