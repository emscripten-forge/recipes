#!/bin/bash

set -e


# the first agument is the path to the recipes directory

RECIPE_DIR=$1
ARCH=$2

# if arch is not set, build both
BUILD_WASM32=true
BUILD_WASM64=true

if [ "$ARCH" == "wasm32" ]; then
    BUILD_WASM64=false
elif [ "$ARCH" == "wasm64" ]; then
    BUILD_WASM32=false
fi


if [ "$BUILD_WASM32" = true ]; then
    echo "Building ${RECIPE_DIR} for emscripten-wasm32"
    rattler-build build \
        -c  https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x \
        -c microsoft \
        -c conda-forge \
        --target-platform emscripten-wasm32 \
        -m variant.yaml \
        --recipe $RECIPE_DIR
fi


if [ "$BUILD_WASM64" = true ]; then
    echo "Building ${RECIPE_DIR} for emscripten-wasm64"
    rattler-build build \
        -c  https://repo.prefix.dev/emscripten-forge-bot/emscripten-forge-6x \
        -c microsoft \
        -c conda-forge \
        --target-platform emscripten-wasm64 \
        -m variant.yaml \
        --recipe $RECIPE_DIR
fi
