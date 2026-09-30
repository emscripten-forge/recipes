#!/bin/bash
set -ex

cd project/emscripten

unset BUILD_DIR

make release

OUT_DIR="$PREFIX/share/boxedwine-single-thread"
mkdir -p "$OUT_DIR"

cp Build/Release/boxedwine.html "$OUT_DIR/"
cp Build/Release/boxedwine.js "$OUT_DIR/"
cp Build/Release/boxedwine.wasm "$OUT_DIR/"
