
mkdir build
cd build

if [[ $target_platform == "emscripten-32" ]]; then
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
    -DCMAKE_FIND_DEBUG_MODE=OFF \

# Build step
ninja install
