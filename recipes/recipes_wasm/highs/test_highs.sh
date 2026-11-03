#!/bin/bash
set -euo pipefail

# Link libhighs.a into a small program that solves an LP through the C++ API
# and run it under node. This exercises the solver (and its task scheduler)
# in a build without pthreads.
em++ -O2 -fwasm-exceptions -I"${PREFIX}/include/highs" test_highs.cpp \
    -L"${PREFIX}/lib" -lhighs -sALLOW_MEMORY_GROWTH=1 -o test_highs.js
node test_highs.js | tee test.log
grep -q "HIGHS TEST OK" test.log
