#!/bin/bash

export LIBRARY_PATH="$LIBRARY_PATH;$PREFIX/lib"
export LD_LIBRARY_PATH="$LIBRARY_PATH;$PREFIX/lib"

${PYTHON} -m pip install .
