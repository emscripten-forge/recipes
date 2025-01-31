mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# clear LDFLAGS flags because they contain sWASM_BIGINT
export LDFLAGS=""

# Configure step
emcmake cmake ${CMAKE_ARGS} -S ../clang -B .        \
    -GNinja                                         \
    -DCMAKE_BUILD_TYPE=MinSizeRel                   \
    -DCMAKE_PREFIX_PATH=$PREFIX                     \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                  \

# Build step
ninja

# Install step
ninja install
