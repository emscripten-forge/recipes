#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building msgpack-c tests..."
echo "=========================================="

em++ tests/test_msgpack.cpp \
  -I"${PREFIX}/include" \
  -DMSGPACK_NO_BOOST \
  -std=c++11 \
  -o test_msgpack.js

echo "Running msgpack-c tests..."
node test_msgpack.js

echo "=========================================="
echo "All msgpack-c tests passed!"
echo "=========================================="
