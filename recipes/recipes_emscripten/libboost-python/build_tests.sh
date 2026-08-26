#!/usr/bin/env bash
set -euo pipefail

# Confirm the archive is a valid emscripten static library — listable by emar
# and containing object files. A full compile+link test needs Python.h and
# the cross-python venv, which isn't reliably set up in the test environment;
# the deeper functional check belongs in a downstream pytester test.

ARCHIVE=$(ls "${PREFIX}"/lib/libboost_python*.a | head -n1)
echo "Inspecting ${ARCHIVE}"

MEMBERS=$(emar t "${ARCHIVE}")
echo "${MEMBERS}"
echo "${MEMBERS}" | grep -q '\.o$' \
  || { echo "Archive has no object members"; exit 1; }

echo "libboost_python archive inspection OK"
