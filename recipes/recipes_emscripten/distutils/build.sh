#!/bin/bash

set -e

export LDFLAGS="$LDFLAGS -sWASM_BIGINT"

# Build and install distutils package
${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation