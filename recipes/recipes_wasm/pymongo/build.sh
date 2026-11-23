#!/bin/bash
set -e

# Fail the build if the optional C extensions do not compile, instead of
# silently falling back to the pure-Python implementation.
export PYMONGO_C_EXT_MUST_BUILD=1

${PYTHON} -m pip install . --no-deps -vv ${PIP_ARGS}
