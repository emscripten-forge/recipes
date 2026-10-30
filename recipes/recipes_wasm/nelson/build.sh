mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# nelson requests Eigen3 3.3 via find_package, but 6x ships Eigen 5 whose
# config rejects that version; use nelson's env override instead.
export EIGEN3_DIR=$PREFIX/share/eigen3/cmake
export EIGEN3_INCLUDE_DIR=$PREFIX/include/eigen3

# Configure step
cmake ${CMAKE_ARGS} ..                                \
    -GNinja                                           \
    -DCMAKE_BUILD_TYPE=Release                        \
    -DCMAKE_PREFIX_PATH=$PREFIX                       \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                    \
    -DCMAKE_POSITION_INDEPENDENT_CODE=ON              \
    -DBUILD_SHARED_LIBS=OFF

# Build step
ninja

ninja install
