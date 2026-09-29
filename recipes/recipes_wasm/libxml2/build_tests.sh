#!/bin/bash
set -e

# Standalone-executable flags (not a SIDE_MODULE, since we invoke via node).
export CFLAGS="${CFLAGS} ${EM_FORGE_CFLAGS_BASE} -I${PREFIX}/include"
export LDFLAGS="${LDFLAGS} ${EM_FORGE_LDFLAGS_BASE}"

emcmake cmake -S tests -B build_tests \
    -GNinja \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -Dlibxml2_DIR="${PREFIX}/lib/cmake/libxml2"

emmake ninja -C build_tests

# When linking against the shared lib, node needs to locate it beside the test.
if [ -f "${PREFIX}/lib/libxml2.so" ]; then
    cp "${PREFIX}/lib/libxml2.so" build_tests/
fi

echo "Running libxml2 link tests..."
node build_tests/test_libxml2.js
