mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

# Configure step
emcmake cmake -DCMAKE_BUILD_TYPE=Release               \
    -DCMAKE_PREFIX_PATH=$PREFIX                        \
    -DLLVM_DIR=$PREFIX/lib/cmake/llvm                  \
    -DLLD_DIR=$PREFIX/lib/cmake/lld                    \
    -DClang_DIR=$PREFIX/lib/cmake/clang                \
    -DBUILD_SHARED_LIBS=ON                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                     \
    ../

# Build step
emmake make -j1

# Install step
emmake make install