#!/bin/bash
export LDFLAGS="$LDFLAGS -L${PREFIX}/lib"
${PYTHON} -m pip  install .
