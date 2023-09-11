mkdir build
cd build

cmake -GNinja ${CMAKE_ARGS} .. \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DLFORTRAN_BUILD_TO_WASM=ON \
    -DWITH_LLVM=OFF \
    -DLFORTRAN_BUILD_ALL=ON \
    -DLFORTRAN_BUILD_TO_WASM=ON \
    -DWITH_STACKTRACE=OFF

ninja
ninja install