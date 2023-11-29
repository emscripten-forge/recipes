mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

if [[ $target_platform == "emscripten-wasm32" ]]; then
    export USE_WASM=ON
else
    export USE_WASM=OFF
fi

ls $PREFIX/lib
echo "BUILDING"

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -Dtabulate_DIR=$PREFIX/lib/cmake/tabulate         \
    -DXSQL_BUILD_XSQLITE_EXECUTABLE=OFF               \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON 

# Build step
ninja

ninja install
