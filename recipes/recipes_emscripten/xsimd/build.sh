
#!/bin/bash
set -e

# Configure step
mkdir -p build
cd build
emcmake cmake .. \
    -DBUILD_TESTS=ON \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH=$PREFIX \
    -DCMAKE_INSTALL_PREFIX=$PREFIX \
    -DDOWNLOAD_DOCTEST=ON

emmake make -j4

# Install step
emmake make install
cd ..

# Copy test files to $PREFIX/test
mkdir -p $PREFIX/bin
cp test/test_wasm/browser_main.html $PREFIX/bin/
cp test/test_wasm/test_wasm_playwright.py $PREFIX/bin/
cp build/test/test_xsimd.js $PREFIX/bin/
cp build/test/test_xsimd.wasm $PREFIX/bin/
