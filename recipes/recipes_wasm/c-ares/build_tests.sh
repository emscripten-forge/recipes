#!/bin/bash
set -exuo pipefail

# c-ares: build and run a real test that exercises the library API.

emcc -O2 \
    tests/test_cares.c \
    -I${PREFIX}/include \
    -L${PREFIX}/lib \
    -lcares \
    -o test_cares.js

echo "c-ares test build succeeded"
node test_cares.js
echo "c-ares test run succeeded"
