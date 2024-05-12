mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# # todo move to xeus-sqlite itself
# cp $RECIPE_DIR/CMakeLists.txt . 

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
    -DXSQL_BUILD_SHARED=OFF                           \
    -DXSQL_BUILD_STATIC=ON                            \
    -DXSQL_USE_SHARED_XEUS=OFF                        \
    -DXSQL_USE_SHARED_XEUS_SQLITE=OFF                 \
    -DXVEGA_STATIC_LIBRARY=$PREFIX/lib/libxvega.a     \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON 

# Build step
ninja

ninja install
