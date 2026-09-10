#!/bin/bash
set -ex

cd project/emscripten

unset BUILD_DIR

make multiThreaded

OUT_DIR="$PREFIX/share/boxedwine-multi-thread"
mkdir -p "$OUT_DIR"

cp Build/MultiThreaded/boxedwine.html "$OUT_DIR/"
cp Build/MultiThreaded/boxedwine.js "$OUT_DIR/"
cp Build/MultiThreaded/boxedwine.wasm "$OUT_DIR/"
