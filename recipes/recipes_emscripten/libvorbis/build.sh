#!/usr/bin/env bash
set -euxo pipefail
cmake ${CMAKE_ARGS:-} -S . -B build -GNinja -DCMAKE_BUILD_TYPE=Release -DCMAKE_INSTALL_PREFIX="$PREFIX" -DCMAKE_PREFIX_PATH="$PREFIX" -DBUILD_SHARED_LIBS=OFF -DBUILD_TESTING=OFF
cmake --build build
cmake --install build
