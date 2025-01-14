#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX --host --host-alias  wasm32-unknown-emscripten
emmake make -j ${CPU_COUNT:-3} install
