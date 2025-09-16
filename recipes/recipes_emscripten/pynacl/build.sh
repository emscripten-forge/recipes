#!/bin/bash

# Configure cross-compilation for bundled libsodium
# PyNaCl will build its bundled libsodium during pip install
# We need to set environment variables that will be passed to libsodium's configure script

# Set the configure arguments for the bundled libsodium
export LIBSODIUM_CONFIGURE_ARGS="--host=wasm32-unknown-emscripten"

# Alternative environment variables that PyNaCl might use
export CONFIGURE_ARGS="--host=wasm32-unknown-emscripten"
export CHOST="wasm32-unknown-emscripten"

# Build PyNaCl
$PYTHON -m pip install . $PIP_ARGS