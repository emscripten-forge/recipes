#!/bin/bash

CFLAGS="-fPIC" emconfigure ./configure  --prefix=$PREFIX --host emscripten-wasm32
emmake make -j ${CPU_COUNT:-3} install
