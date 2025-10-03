#!/bin/bash
set -e

# Build SDL2 using emscripten's embuilder
echo "Building SDL2 for emscripten..."
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build sdl2 --pic

# Also build SDL2 extensions that pygame-ce needs
# Note: SDL2 ports in emscripten use underscores, not hyphens
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build sdl2_image --pic
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build sdl2_mixer --pic  
$EMSCRIPTEN_FORGE_EMSDK_DIR/upstream/emscripten/embuilder build sdl2_ttf --pic

# Set environment variables for pygame build
export SDL_VERSION=2.0

# Set up cross compilation with meson
export MESON_CROSS_FILE=$RECIPE_DIR/emscripten.meson.cross

# Install pygame-ce using pip which will invoke meson-python with cross-compilation
echo "Installing pygame-ce..."
python -m pip install . -vv --no-deps --no-build-isolation \
    -Csetup-args="--cross-file=$MESON_CROSS_FILE"