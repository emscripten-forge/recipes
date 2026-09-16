#!/usr/bin/env bash
set -e

# Tiny Boost.Python consumer used to end-to-end verify libboost-python:
# builds a real emscripten Python extension against the installed static
# libraries and installs it into site-packages so a pytester test can
# import it and exercise `add(2, 3)`.

BUILD_DIR="${SRC_DIR}/_example_build"
mkdir -p "${BUILD_DIR}"
cp "${RECIPE_DIR}"/example/mymodule.cpp \
   "${RECIPE_DIR}"/example/setup.py \
   "${RECIPE_DIR}"/example/pyproject.toml \
   "${BUILD_DIR}/"
cd "${BUILD_DIR}"

${PYTHON} -m pip install . ${PIP_ARGS}
