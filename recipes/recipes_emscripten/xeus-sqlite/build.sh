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
    -XSQL_BUILD_SHARED=OFF                            \
    -DXSQL_BUILD_STATIC=ON                            \
    -XSQL_USE_SHARED_XEUS=OFF                         \
    -DXSQL_USE_SHARED_XEUS_SQLITE=OFF                 \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON 

# Build step
ninja

ninja install
