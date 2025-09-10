#!/bin/bash

set -euo pipefail

# Build SDL2 for emscripten (required by pyxel)
embuilder build sdl2 --pic

# Set environment variables for maturin and emscripten
export MATURIN_PYTHON_SYSCONFIGDATA_DIR=${PREFIX}/etc/conda/_sysconfigdata__emscripten_wasm32-emscripten.py
export PYO3_USE_ABI3_FORWARD_COMPATIBILITY=1

# Change to the Python subdirectory where pyproject.toml is located
cd python

# Copy LICENSE file
cp ../LICENSE pyxel/

# Install using pip (which will use maturin via pyproject.toml)
${PYTHON} -m pip install . -vvv