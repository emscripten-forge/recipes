#!/bin/bash

export CFLAGS="${CFLAGS} -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -fwasm-exceptions"

${PYTHON} -m pip install . --no-deps -v
