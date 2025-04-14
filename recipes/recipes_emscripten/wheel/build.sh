#!/bin/bash

export LDFLAGS="$LDFLAGS -sWASM_BIGINT"


${PYTHON} -m pip install . -vvv --no-deps --no-build-isolation 
