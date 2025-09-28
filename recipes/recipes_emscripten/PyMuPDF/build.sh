#!/bin/bash

set -euo pipefail

# PyMuPDF WebAssembly build script
# This addresses font resource linking issues specific to emscripten

# Try minimal bindings to avoid MuPDF compilation entirely
export PYMUPDF_SETUP_FLAVOUR="b"  # Basic bindings - minimum MuPDF interaction
export PYMUPDF_SETUP_MUPDF_TESSERACT=0  # Disable Tesseract
export HAVE_LIBCRYPTO=no  # Disable crypto

# Disable MuPDF rebuild to avoid WebAssembly compilation issues
export PYMUPDF_SETUP_MUPDF_REBUILD=0

# Try to avoid MuPDF build entirely for WebAssembly compatibility
export PYMUPDF_SETUP_MUPDF_BUILD=""  # No MuPDF build

# Configure MuPDF makefile to avoid font resource embedding
# These environment variables are passed to the MuPDF build system
# TOFU flags disable CJK font embedding which causes WebAssembly issues
export XCFLAGS="-DTOFU_CJK_EXT -DNOCJK -DNO_CJK -DTOFU_NOTO -DTOFU -DNOCJK_FULL"
export XCXXFLAGS="-DTOFU_CJK_EXT -DNOCJK -DNO_CJK -DTOFU_NOTO -DTOFU -DNOCJK_FULL"

# Disable all resource embedding to avoid WebAssembly linking issues
export NO_EMBEDDED_FONTS=1

# WebAssembly-specific MuPDF configuration
export PYMUPDF_SETUP_MUPDF_BUILD_TYPE="release" 
export PYMUPDF_SETUP_MUPDF_THIRD=0  # Disable third-party font embedding
export HAVE_GLUT=no  # Disable OpenGL
export HAVE_X11=no  # Disable X11

# Force static linking to avoid WebAssembly shared library issues
export PYMUPDF_SETUP_MUPDF_BSYMBOLIC=0  # Disable -Bsymbolic linking

# MuPDF makefile environment to build static libraries only
# Skip shared library targets that cause WebAssembly linking issues  
export MUPDF_STATIC_ONLY=1

# Tell PyMuPDF to build without shared libraries altogether
# This should prevent the shared library build that's causing the linking issues
export XLIB_LDFLAGS=""  # Clear LDFLAGS to avoid shared library options

# Force PyMuPDF to think we're not on Linux to avoid shared library build
# This is a workaround for WebAssembly cross-compilation
export FORCE_STATIC_BUILD=1

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

# Provide Python development headers for cross-compilation
# These are needed because python-config is not available in emscripten environment
PY_VER=$(${PYTHON} -c "import sys; print(f'{sys.version_info.major}.{sys.version_info.minor}')")
export PYTHON_INCLUDE_DIR="${PREFIX}/include/python${PY_VER}"
export PYTHON_LIBRARY_DIR="${PREFIX}/lib"

# Set up environment variables that PyMuPDF's build system expects
export CFLAGS="${CFLAGS} -I${PYTHON_INCLUDE_DIR}"
export CPPFLAGS="${CPPFLAGS:-} -I${PYTHON_INCLUDE_DIR}"

# Create a fake python-config script since PyMuPDF's build system expects it
# Create it in both BUILD_PREFIX and PREFIX to catch all cases
for BIN_DIR in "${BUILD_PREFIX}/bin" "${PREFIX}/bin"; do
    mkdir -p "${BIN_DIR}"
    cat > "${BIN_DIR}/python-config" << EOF
#!/bin/bash
case "\$1" in
    --includes)
        echo "-I${PYTHON_INCLUDE_DIR}"
        ;;
    --ldflags)
        echo "-L${PYTHON_LIBRARY_DIR}"
        ;;
    --libs)
        echo ""
        ;;
    --cflags)
        echo "-I${PYTHON_INCLUDE_DIR}"
        ;;
    *)
        echo "Unknown option: \$1" >&2
        exit 1
        ;;
esac
EOF

    # Also create a fake python3-config linking to python-config
    ln -sf "${BIN_DIR}/python-config" "${BIN_DIR}/python3-config"

    # Make them executable
    chmod +x "${BIN_DIR}/python-config"
    chmod +x "${BIN_DIR}/python3-config"
done

# Make sure our fake python-config comes first in PATH
export PATH="${BUILD_PREFIX}/bin:${PATH}"

echo "=== PyMuPDF Emscripten Build Configuration ==="
echo "PYMUPDF_SETUP_FLAVOUR=$PYMUPDF_SETUP_FLAVOUR"
echo "PYMUPDF_SETUP_MUPDF_BUILD=$PYMUPDF_SETUP_MUPDF_BUILD"
echo "PYMUPDF_SETUP_MUPDF_REBUILD=$PYMUPDF_SETUP_MUPDF_REBUILD"
echo "XCFLAGS=$XCFLAGS"
echo "PYTHON_INCLUDE_DIR=$PYTHON_INCLUDE_DIR"
echo "PYTHON_LIBRARY_DIR=$PYTHON_LIBRARY_DIR"
echo "==============================================="

# Create a hook to modify MuPDF makefile for WebAssembly compatibility
# PyMuPDF will clone MuPDF during the build process, then we can patch it
export PYMUPDF_SETUP_MUPDF_OVERWRITE_CONFIG=0  # Don't overwrite our config

# Force static linking and disable resource embedding via make variables
export EMBED_FONT_OBJS=""
export EMBED_ICC_OBJS=""
export EMBED_CJK_OBJS=""

# Since we're avoiding MuPDF build entirely, no need for patching

# Install PyMuPDF
${PYTHON} -m pip install . ${PIP_ARGS} --verbose --no-build-isolation