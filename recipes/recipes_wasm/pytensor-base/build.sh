#!/bin/bash
set -ex

# Build with PYODIDE=1 to skip the cython extension (scan_perform) and
# produce a pure-python wheel, as pytensor's C compilation is unavailable
# under emscripten. This corresponds to pytensor's "Python mode".
# See https://www.pymc-labs.com/blog-posts/pymc-in-browser
PYODIDE=1 ${PYTHON} -m pip install . ${PIP_ARGS} --no-build-isolation
