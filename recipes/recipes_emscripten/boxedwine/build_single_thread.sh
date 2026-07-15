#!/bin/bash
set -ex

cd project/emscripten

unset BUILD_DIR

make release

OUT_DIR="$PREFIX/share/boxedwine"
mkdir -p "$OUT_DIR"

cp -r Build/Release/* "$OUT_DIR/"