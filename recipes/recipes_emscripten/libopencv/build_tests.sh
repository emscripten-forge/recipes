#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build_tests"

rm -rf "$BUILD_DIR"

export CFLAGS="${CFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS:-} $EM_FORGE_SIDE_MODULE_CFLAGS -sSUPPORT_LONGJMP=wasm -fwasm-exceptions"
# Do not use EM_FORGE_SIDE_MODULE_LDFLAGS here: the test is an executable,
# not a side module, so SIDE_MODULE=1 would conflict with MAIN_MODULE=1.

emcmake cmake \
    -S "$SCRIPT_DIR/tests" \
    -B "$BUILD_DIR" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DOpenCV_DIR="${PREFIX}/lib/cmake/opencv5"

ninja -C "$BUILD_DIR"

OUTPUT="$(cd "$BUILD_DIR" && node test_opencv.js 2>&1)"
echo "$OUTPUT"
if grep -q "All tests passed" <<<"$OUTPUT"; then
    echo "Test PASSED"
    exit 0
fi

echo "Test FAILED"
exit 1
