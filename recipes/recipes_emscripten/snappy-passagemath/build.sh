#!/usr/bin/env bash
set -euxo pipefail

# CyOpenGL needs a real GL library, which the browser build does not have.
# setup.py skips it when no GL headers are found; make sure it is never forced.
export SNAPPY_ALWAYS_BUILD_CYOPENGL=False

# SnapPy and SnapPyHP are built from the same sources with a different Real
# type, so they define the same kernel symbols.  Emscripten side modules
# export every symbol with default visibility into one process-wide table, so
# whichever loads second would bind its kernel calls - and its Cython module
# state - to the first one's.  Hide everything except the module init
# functions, which carry visibility("default") through PyMODINIT_FUNC.
export CFLAGS="${CFLAGS:-} -fvisibility=hidden"
export CXXFLAGS="${CXXFLAGS:-} -fvisibility=hidden"

${PYTHON} -m pip install . ${PIP_ARGS}
