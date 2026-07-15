#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building FFmpeg tests..."
echo "=========================================="

raw_test_type="${1:?usage: build_tests.sh libs or cli}"
test_type="${raw_test_type%\}}"

if [[ "${test_type}" == "cli" ]]; then
  node "${PREFIX}/bin/ffmpeg.js" -version
  node "${PREFIX}/bin/ffprobe.js" -version
  exit 0
fi

if [[ "${test_type}" != "libs" ]]; then
  echo "error: unknown test type: ${test_type}" >&2
  exit 2
fi

export PKG_CONFIG_PATH="${PREFIX}/lib/pkgconfig:${PKG_CONFIG_PATH:-}"
export CFLAGS="${CFLAGS:-}"
export LDFLAGS="${LDFLAGS:-}"

mkdir -p build_tests
cd build_tests

emcmake cmake ../tests \
  -G Ninja \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake ninja

echo "Running FFmpeg tests..."
node test_ffmpeg.js

echo "=========================================="
echo "All FFmpeg tests passed!"
echo "=========================================="
