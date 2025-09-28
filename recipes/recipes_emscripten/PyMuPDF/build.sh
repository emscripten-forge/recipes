#!/bin/bash

set -euo pipefail

# PyMuPDF WebAssembly build script
# This addresses font resource linking issues specific to emscripten

# Use pure bindings without MuPDF shared libraries to avoid font linking issues
export PYMUPDF_SETUP_FLAVOUR=p  # Pure Python bindings only, no shared libs
export PYMUPDF_SETUP_MUPDF_TESSERACT=0  # Disable Tesseract
export HAVE_LIBCRYPTO=no  # Disable crypto

# Disable MuPDF rebuild to use a simpler build process
export PYMUPDF_SETUP_MUPDF_REBUILD=0

# Try to use system MuPDF if available to avoid building embedded fonts
export PYMUPDF_SETUP_MUPDF_BUILD=

# Configure MuPDF makefile to avoid font resource embedding
# These environment variables are passed to the MuPDF build system
export XCFLAGS="-DTOFU_CJK_EXT -DNOCJK -DNO_CJK -DTOFU_NOTO -DTOFU"
export XCXXFLAGS="-DTOFU_CJK_EXT -DNOCJK -DNO_CJK -DTOFU_NOTO -DTOFU"

# Override default MuPDF configuration to minimize dependencies
export HAVE_HARFBUZZ=no
export HAVE_FREETYPE=no
export HAVE_GUMBO=no
export HAVE_TESSERACT=no
export HAVE_LCMS2=no
export HAVE_JPEGXR=no

# Emscripten-specific build flags
export CFLAGS="${CFLAGS:-} -fPIC -Os"
export CXXFLAGS="${CXXFLAGS:-} -fPIC -Os"
export LDFLAGS="${LDFLAGS:-} -s WASM=1 -sWASM_BIGINT"

echo "=== PyMuPDF Emscripten Build Configuration ==="
echo "PYMUPDF_SETUP_FLAVOUR=$PYMUPDF_SETUP_FLAVOUR"
echo "PYMUPDF_SETUP_MUPDF_REBUILD=$PYMUPDF_SETUP_MUPDF_REBUILD"
echo "XCFLAGS=$XCFLAGS"
echo "==============================================="

# Install PyMuPDF
${PYTHON} -m pip install . ${PIP_ARGS} --verbose --no-build-isolation