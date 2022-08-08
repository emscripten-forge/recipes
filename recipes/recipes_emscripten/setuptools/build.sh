#!/bin/bash
${PYTHON} -m pip install . --no-deps

find "$BUILD_PREFIX/lib/python$PY_VER/site-packages/setuptools" -name '*.exe' -delete
