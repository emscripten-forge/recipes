#!/usr/bin/env bash
set -euo pipefail

# CGAL is header-only since 5.0. The build simply installs headers plus the
# CMake package config (CGALConfig.cmake) so downstream find_package(CGAL) works.
# No compilation runs here, so we don't need CMAKE_ARGS from emscripten.

mkdir -p build
cd build

cmake .. \
    -GNinja \
    -DCMAKE_INSTALL_PREFIX="${PREFIX}" \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_BUILD_TYPE=Release \
    -DWITH_examples=OFF \
    -DWITH_demos=OFF \
    -DWITH_tests=OFF

ninja install
