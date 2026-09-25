#!/bin/bash
set -euo pipefail

INSTALL_DIR="${PREFIX}/share/libgdal-core-tests"

# Emscripten's Node loader resolves NEEDED dylibs relative to the JS file's
# __dirname, so make the shared libraries visible there.
ln -sf "${PREFIX}/lib/libgdal.so" "$INSTALL_DIR/libgdal.so"
ln -sf "${PREFIX}/lib/libgeos_c.so" "$INSTALL_DIR/libgeos_c.so"
ln -sf "${PREFIX}/lib"/libgeos.so* "$INSTALL_DIR/"
ln -sf "${PREFIX}/lib"/libproj.so* "$INSTALL_DIR/"

echo "=== Running test ==="
set +e
(cd "$INSTALL_DIR" && PROJ_DATA_HOST="${PREFIX}/share/proj" node test_libgdal.js) > "$INSTALL_DIR/test_output.txt" 2>&1
NODE_EXIT=$?
echo "=== Test output ==="
cat "$INSTALL_DIR/test_output.txt"
echo "=== Test end (exit=$NODE_EXIT) ==="

if grep -q "All tests passed" "$INSTALL_DIR/test_output.txt"; then
    echo "Test PASSED"
    exit 0
fi

echo "Test FAILED (node exit=$NODE_EXIT)"
exit 1
