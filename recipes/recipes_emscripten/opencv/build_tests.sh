#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build_tests"

# Clean previous build
rm -rf "$BUILD_DIR"


# Download test image to tests/ so --preload-file can embed it in the WASM virtual FS
LOGO_PNG="$(dirname "$0")/tests/logo.png"
if [ ! -f "$LOGO_PNG" ]; then
    curl -sL -o "$LOGO_PNG" "https://opencv.org/wp-content/uploads/2020/07/OpenCV_logo_no_text_.png"
fi


export CFLAGS="$CFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export CXXFLAGS="$CXXFLAGS $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
# Do NOT use EM_FORGE_SIDE_MODULE_LDFLAGS — the test is an executable (MAIN_MODULE),
# not a side module. SIDE_MODULE=1 would conflict with MAIN_MODULE=1.

emcmake cmake \
    -S "$SCRIPT_DIR/tests" \
    -B "$BUILD_DIR" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH_MODE_LIBRARY=BOTH \
    -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH \
    -DOpenCV_DIR="${PREFIX}/lib/cmake/opencv5"

ninja -C "$BUILD_DIR"

# Run test from build dir so preloaded .data file is found
set +e
cd "$BUILD_DIR"
OUTPUT=$(node test_opencv.js 2>&1)
NODE_EXIT=$?
echo "$OUTPUT"
if echo "$OUTPUT" | grep -q "All tests passed"; then
    echo "Test PASSED"
    exit 0
else
    echo "Test FAILED (node exit=$NODE_EXIT)"
    exit 1
fi
