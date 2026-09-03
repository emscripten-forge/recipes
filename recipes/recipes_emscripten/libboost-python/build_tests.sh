#!/usr/bin/env bash
set -euo pipefail

# Smoke test: compile a minimal Boost.Python module against the installed
# libboost_python and libpython, and verify the archive is a valid emscripten
# static library. This exercises header discovery and static-link ABI, which
# is what downstream consumers (pygplates, rdkit, ...) actually need.

PY_VER=$(ls -d "${PREFIX}"/include/python*/ 2>/dev/null \
    | sed -E 's|.*/python([0-9]+\.[0-9]+)/?$|\1|' | head -n1)
PY_NODOT=${PY_VER//./}
BOOST_PY_LIB="${PREFIX}/lib/libboost_python${PY_NODOT}-${PY_NODOT}.a"
PY_LIB="${PREFIX}/lib/libpython${PY_VER}.a"
PY_INC="${PREFIX}/include/python${PY_VER}"

test -f "${BOOST_PY_LIB}" || { echo "Missing ${BOOST_PY_LIB}"; exit 1; }
test -f "${PY_LIB}" || { echo "Missing ${PY_LIB}"; exit 1; }
test -f "${PY_INC}/Python.h" || { echo "Missing Python.h in ${PY_INC}"; exit 1; }
test -f "${PREFIX}/include/boost/python.hpp" || { echo "Missing boost/python.hpp"; exit 1; }

echo "Inspecting ${BOOST_PY_LIB}"
emar t "${BOOST_PY_LIB}" | head -20
emar t "${BOOST_PY_LIB}" | grep -q '\.o$' \
    || { echo "Archive has no object members"; exit 1; }

echo "Compiling minimal Boost.Python module against Python ${PY_VER}"
em++ -fexceptions -fPIC -std=c++17 \
    -I"${PY_INC}" -I"${PREFIX}/include" \
    -c "$(dirname "$0")/tests/test_boost_python.cpp" \
    -o test_boost_python.o

# Link as an emscripten side module (Python-extension shape). This pulls in
# libboost_python and libpython statically and surfaces any unresolved
# symbols between the two — the class of bug a header-only compile misses.
echo "Linking against libboost_python + libpython"
em++ -fexceptions -sSIDE_MODULE=1 \
    test_boost_python.o \
    "${BOOST_PY_LIB}" "${PY_LIB}" \
    -o _test_boost_python.wasm

test -s _test_boost_python.wasm \
    || { echo "Linker produced empty output"; exit 1; }
echo "Boost.Python smoke module linked OK: $(stat -c %s _test_boost_python.wasm) bytes"
