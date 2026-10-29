#!/bin/bash

export SETUPTOOLS_SCM_PRETEND_VERSION=${PKG_VERSION}
export CFLAGS="${CFLAGS}  -I$BUILD_PREFIX/lib/python$PY_VER/site-packages/numpy/_core/include/"
${PYTHON} -m pip install . --no-deps --no-build-isolation -vv
