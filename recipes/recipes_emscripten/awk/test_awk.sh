#!/bin/bash
set -euo pipefail

OUTPUT=$(run_modularized $PREFIX/bin/awk.js --version)
if [[ "$OUTPUT" != "awk version $PKG_VERSION" ]]; then
  echo "Unexpected version output: $OUTPUT"
  exit 1
fi

OUTPUT=$(run_modularized $PREFIX/bin/awk.js 'BEGIN { print 1 + 1 }')
if [[ "$OUTPUT" != "2" ]]; then
  echo "Unexpected output: $OUTPUT"
  exit 1
fi
