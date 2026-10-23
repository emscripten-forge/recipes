mkdir build
cd build

export CMAKE_PREFIX_PATH=$PREFIX
export CMAKE_SYSTEM_PREFIX_PATH=$PREFIX

unset EM_FORGE_OPTFLAGS
unset EM_FORGE_DBGFLAGS
unset EM_FORGE_LDFLAGS_BASE
unset EM_FORGE_CFLAGS_BASE
unset EM_FORGE_SIDE_MODULE_LDFLAGS
unset EM_FORGE_SIDE_MODULE_CFLAGS

unset CFLAGS
unset LDFLAGS

# Configure step
emcmake cmake -DCMAKE_BUILD_TYPE=Release               \
    -DCMAKE_PREFIX_PATH=$PREFIX                        \
    -DLLVM_DIR=$PREFIX/lib/cmake/llvm                  \
    -DLLD_DIR=$PREFIX/lib/cmake/lld                    \
    -DClang_DIR=$PREFIX/lib/cmake/clang                \
    -DBUILD_SHARED_LIBS=ON                             \
    -DCMAKE_INSTALL_PREFIX=$PREFIX                     \
    -DCPPINTEROP_ENABLE_TESTING=OFF                    \
    ../

# Build step
emmake make -j1

# Install step
emmake make install