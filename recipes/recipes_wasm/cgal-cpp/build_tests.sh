#!/usr/bin/env bash
set -euo pipefail

# Mirrors the antlr-cpp-runtime test pattern: configure the tests/ subdir with
# emcmake, build with emmake, run the resulting .js under Node. If this passes
# we know CGAL's headers install correctly, CGAL::CGAL finds gmp/mpfr under
# Emscripten, and the pygplates code paths (EPICK + Delaunay_triangulation_2 +
# natural_neighbor_coordinates_2) don't blow up under WASM's limited FPU mode.

emcmake cmake -S tests -B build_tests \
    -DCMAKE_BUILD_TYPE=Release \
    -DCMAKE_PREFIX_PATH="${PREFIX}" \
    -DCMAKE_FIND_ROOT_PATH="${PREFIX}"

emmake make -C build_tests -j"${CPU_COUNT:-1}"

echo "Running test..."
node build_tests/test_cgal.js
