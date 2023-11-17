
mkdir build
cd build

if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

# Configure step
cmake ${CMAKE_ARGS} ..             \
    -GNinja                        \
    -DCMAKE_BUILD_TYPE=Release     \
    -DCMAKE_PREFIX_PATH=$PREFIX    \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DXEUS_EMSCRIPTEN_WASM_BUILD=$USE_WASM \
    -DCMAKE_FIND_DEBUG_MODE=OFF \

    # -Dnlohmann_json_DIR=$PREFIX/lib/cmake/nlohmann_json \
    # -Dxtl_DIR=$PREFIX/share/cmake/xtl \

# Build step
ninja install
