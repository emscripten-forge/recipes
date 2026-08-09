#!/bin/bash

export CFLAGS="$CFLAGS -fPIC -O3"
export CXXFLAGS="$CXXFLAGS -fPIC -O3"

export _PYTHON_SYSCONFIGDATA_NAME=_sysconfigdata__emscripten_wasm32-emscripten

${PYTHON} setup.py package_assemble
${PYTHON} -m pip install . -vv --no-build-isolation
