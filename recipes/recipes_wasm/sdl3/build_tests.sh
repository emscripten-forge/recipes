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

# Run the bundled browser demo headlessly when it is part of the package.
if [ -f "$PREFIX/share/sdl3-demo/sdl3-demo.js" ]; then
    bash run_demo.sh
fi
