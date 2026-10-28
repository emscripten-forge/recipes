#!/bin/bash
set -euo pipefail

emcmake cmake -S "$SRC_DIR/demo" -B build-demo -GNinja \
    ${CMAKE_ARGS:-} \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_INSTALL_PREFIX="$PREFIX" \
    -DCMAKE_PREFIX_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
    -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH

emmake ninja -C build-demo -j"${CPU_COUNT:-1}"
emmake ninja -C build-demo install
