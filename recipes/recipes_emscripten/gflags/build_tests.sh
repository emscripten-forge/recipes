#!/bin/bash
set -euo pipefail

if [ -n "${BUILD_PREFIX:-}" ] && [ -f "${BUILD_PREFIX}/bin/activate_emscripten.sh" ]; then
  source "${BUILD_PREFIX}/bin/activate_emscripten.sh"
  export PATH="${BUILD_PREFIX}/bin:${PATH}"
  export PYTHON="${BUILD_PREFIX}/bin/python3"
  export EMSDK_PYTHON="${BUILD_PREFIX}/bin/python3"
fi

emxx_cmd="${BUILD_PREFIX:-}/bin/em++"
node_cmd="${BUILD_PREFIX:-}/bin/node"

if [ ! -x "${emxx_cmd}" ]; then
  emxx_cmd="$(command -v em++)"
fi

if [ ! -x "${node_cmd}" ]; then
  node_cmd="$(command -v node)"
fi

"${emxx_cmd}" tests/test_gflags.cpp \
  -I"${PREFIX}/include" \
  -L"${PREFIX}/lib" \
  -lgflags \
  -o test_gflags.js

"${node_cmd}" test_gflags.js