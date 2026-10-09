#!/usr/bin/env bash
set -euxo pipefail
cp "$RECIPE_DIR/CMakeLists.txt" CMakeLists.txt
cmake ${CMAKE_ARGS:-} -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX"
cmake --build build
cmake --install build
