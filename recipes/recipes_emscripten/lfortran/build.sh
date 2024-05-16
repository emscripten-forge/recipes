set -e
set -x

mkdir -p src/bin/asset_dir
cp -v $BUILD_PREFIX/share/lfortran/lib/*.mod src/bin/asset_dir

emcmake cmake \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_CXX_FLAGS_DEBUG="-Wall -Wextra -fexceptions" \
    -DCMAKE_CXX_FLAGS_RELEASE="-Wall -Wextra -fexceptions" \
    -DWITH_LLVM=no \
    -DLFORTRAN_BUILD_ALL=no \
    -DLFORTRAN_BUILD_TO_WASM=yes \
    -DWITH_STACKTRACE=no \
    -DCMAKE_PREFIX_PATH="$CMAKE_PREFIX_PATH_LFORTRAN;$CONDA_PREFIX" \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    .

# Build step
emmake make -j8

# Install step
emmake make install