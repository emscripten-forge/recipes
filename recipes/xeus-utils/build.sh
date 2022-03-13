
mkdir build
cd build

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -Dnlohmann_json_DIR=$BUILD_PREFIX/lib/cmake/nlohmann_json \
    -Dxtl_DIR=$BUILD_PREFIX/share/cmake/xtl \
    -DCLI11_DIR=$BUILD_PREFIX/share/cmake/CLI11 \
    -Dxeus_DIR=$PREFIX/lib/cmake/xeus \
    -DXEUS_UTILS_EMSCRIPTEN_WASM_BUILD=ON\

# Build step
ninja install
