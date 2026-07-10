#!/bin/bash
set -ex

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

# Compile the test together with the rebound source files (static build).
# The .so side module cannot be statically linked by wasm-ld, so we
# compile everything into a standalone executable.
# The Python rebound recipe tests the .so loading via ctypes.
TEST_CFLAGS="${EM_FORGE_CFLAGS_BASE:-${CFLAGS}}"
TEST_LDFLAGS="${EM_FORGE_LDFLAGS_BASE:-${LDFLAGS/-s SIDE_MODULE=1/}}"
TEST_LDFLAGS="${TEST_LDFLAGS//-sSIDE_MODULE=1/}"

emcc ${TEST_CFLAGS} ${SCRIPT_DIR}/tests/test_rebound.c \
    src/*.c \
    -Isrc \
    -lm \
    ${TEST_LDFLAGS} \
    -sALLOW_MEMORY_GROWTH=1 \
    -o test_rebound.js

# Run it with node
node test_rebound.js
