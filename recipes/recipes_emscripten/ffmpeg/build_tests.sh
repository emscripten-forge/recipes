#!/bin/bash
set -euo pipefail

echo "=========================================="
echo "Building FFmpeg tests..."
echo "=========================================="

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
node "${PREFIX}/bin/ffmpeg.js" -version
node "${PREFIX}/bin/ffprobe.js" -version

echo "=========================================="
echo "All FFmpeg tests passed!"
echo "=========================================="
