#!/bin/bash

set -e


# the first agument is the path to the recipes directory

RECIPE_DIR=$1

echo "Building ${RECIPE_DIR} for emscripten-wasm64"
rattler-build build \
    -c  https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x \
    -c microsoft \
    -c conda-forge \
    --target-platform emscripten-wasm64 \
    -m variant.yaml \
    --recipe $RECIPE_DIR
    
echo "Building ${RECIPE_DIR} for emscripten-wasm32"
rattler-build build \
    -c  https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x \
    -c microsoft \
    -c conda-forge \
    --target-platform emscripten-wasm32 \
    -m variant.yaml \
    --recipe $RECIPE_DIR

