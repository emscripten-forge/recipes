#!/bin/bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="$SCRIPT_DIR/_build_tests"

rm -rf "$BUILD_DIR"

emcmake cmake \
    -S "$SCRIPT_DIR/tests" \
    -B "$BUILD_DIR" \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}"

ninja -C "$BUILD_DIR"

# Emscripten's Node loader resolves NEEDED dylibs relative to the JS file's
# __dirname, so make the shared libraries visible there.
ln -sf "${PREFIX}/lib/libgdal.so" "$BUILD_DIR/libgdal.so"
ln -sf "${PREFIX}/lib/libgeos_c.so" "$BUILD_DIR/libgeos_c.so"
ln -sf "${PREFIX}/lib"/libgeos.so* "$BUILD_DIR/"

echo "=== Running test ==="
set +e
(cd "$BUILD_DIR" && node test_libgdal.js) > "$BUILD_DIR/test_output.txt" 2>&1
NODE_EXIT=$?
echo "=== Test output ==="
cat "$BUILD_DIR/test_output.txt"
echo "=== Test end (exit=$NODE_EXIT) ==="

if grep -q "All tests passed" "$BUILD_DIR/test_output.txt"; then
    echo "Test PASSED"
    exit 0
fi

echo "Test FAILED (node exit=$NODE_EXIT)"
exit 1
