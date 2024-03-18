mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# Configure step
emcmake  cmake -DCMAKE_BUILD_TYPE=Release               \
    -DUSE_CLING=OFF                                     \
    -DUSE_REPL=ON                                       \
    -DCMAKE_PREFIX_PATH=$PREFIX                         \
    -DLLVM_DIR=$PREFIX                                  \
    -DClang_DIR=$PREFIX                                 \
    -DBUILD_SHARED_LIBS=OFF                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                      \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=ON              \
    ../

# Build step
EMCC_CFLAGS='-sERROR_ON_UNDEFINED_SYMBOLS=0' emmake make -j1

# Install step
emmake make install
