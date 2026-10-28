#!/bin/bash
set -euo pipefail

emcmake cmake -S tests -B build_tests -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH

emmake ninja -C build_tests
node build_tests/test_sdl3.js

# Build the browser demo from the recipe sources and run it headlessly. The
# demo is intentionally not installed into the output package.
emcmake cmake -S demo -B build_demo -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH

emmake ninja -C build_demo
bash run_demo.sh "$PWD/build_demo/sdl3-demo.js"
