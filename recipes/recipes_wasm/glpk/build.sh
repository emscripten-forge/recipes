#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX --host wasm32-unknown-emscripten
emmake make -j ${CPU_COUNT:-3} install


rm -r $PREFIX/bin/glpsol
