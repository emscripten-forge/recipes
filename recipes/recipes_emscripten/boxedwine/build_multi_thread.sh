#!/bin/bash
set -ex

cd project/emscripten

unset BUILD_DIR

make multiThreaded

OUT_DIR="$PREFIX/share/boxedwine-multi-thread"
mkdir -p "$OUT_DIR"

cp -r Build/MultiThreaded/* "$OUT_DIR/"