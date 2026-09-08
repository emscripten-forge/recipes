#!/bin/bash
set -euo pipefail

BUILD_DIR="$SRC_DIR/_build_tests"
INSTALL_DIR="${PREFIX}/share/libgdal-core-tests"

rm -rf "$BUILD_DIR"

emcmake cmake \
    -S "$RECIPE_DIR/tests" \
    -B "$BUILD_DIR" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}"

ninja -C "$BUILD_DIR"

mkdir -p "$INSTALL_DIR"
cp "$BUILD_DIR/test_libgdal.js" "$BUILD_DIR/test_libgdal.wasm" "$INSTALL_DIR/"
