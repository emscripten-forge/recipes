#!/usr/bin/env bash
set -euxo pipefail

# 1. Generate the configure script from the source
autoreconf --install

# 2. Configure the build for the emscripten-forge prefix.
# We disable shared libraries to ensure a static .a archive is produced for WebAssembly.
emconfigure ./configure \
    --prefix=$PREFIX \
    --disable-shared \
    --enable-static

# 3. Build the library
emmake make

# 4. Install the library and headers into the prefix environment
emmake make install