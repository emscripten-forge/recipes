#!/bin/bash

export CFLAGS="${CFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export LDFLAGS="${LDFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS} -sRELOCATABLE=1 -fwasm-exceptions"

${PYTHON} -m pip install . --no-deps -v
