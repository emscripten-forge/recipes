#!/bin/bash
set -euo pipefail

emcmake cmake -S tests -B build_tests -G Ninja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake ninja -C build_tests

if [ -f "${PREFIX}/lib/libglfw3.so" ]; then
    cp -f "${PREFIX}/lib/libglfw3.so" build_tests/
fi

node build_tests/test_glfw.js | tee test_glfw.log
grep -q "pongasoft/emscripten-glfw@v" test_glfw.log
