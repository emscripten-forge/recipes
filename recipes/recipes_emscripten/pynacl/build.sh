#!/bin/bash

# Configure cross-compilation for PyNaCl's bundled libsodium
# PyNaCl builds its bundled libsodium and needs to know about cross-compilation

# Set environment variables that autotools/configure scripts recognize
export CHOST="wasm32-unknown-emscripten"

# PyNaCl specific environment variables for bundled libsodium
export LIBSODIUM_MAKE_ARGS=""
export LIBSODIUM_CONFIGURE_ARGS="--host=wasm32-unknown-emscripten"

# Build PyNaCl
$PYTHON -m pip install . $PIP_ARGS