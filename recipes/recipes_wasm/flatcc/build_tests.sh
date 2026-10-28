#!/bin/bash
set -euo pipefail

emcc tests/test_flatcc.c \
  -I"${PREFIX}/include" \
  -L"${PREFIX}/lib" \
  -lflatccrt \
  -o test_flatcc.js

node test_flatcc.js
node "${PREFIX}/bin/flatcc.js" --help >/dev/null