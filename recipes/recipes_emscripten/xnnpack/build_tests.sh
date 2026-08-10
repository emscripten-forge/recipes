#!/bin/bash
set -e

emcmake cmake -S tests -B build_tests \
  -DCMAKE_BUILD_TYPE=Release \
  -DCMAKE_PREFIX_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH="${PREFIX}" \
  -DCMAKE_FIND_ROOT_PATH_MODE_PACKAGE=BOTH \
  -DCMAKE_FIND_ROOT_PATH_MODE_INCLUDE=BOTH

emmake make -C build_tests -j"${CPU_COUNT}"

test_artifact=$(find build_tests -maxdepth 2 -type f \( -name 'libtest_xnnpack*' -o -name 'test_xnnpack*' \) | head -n 1)
if [[ -z "${test_artifact}" ]]; then
  echo "Missing expected linked test artifact" >&2
  exit 1
fi

echo "Built test artifact: ${test_artifact}"
