#!/bin/bash

set -e

cd src

cp makefile.u makefile
if [[ "$OSTYPE" == "darwin"* ]]; then
    sed -i '' "s/gram.c:/gram.c1:/" makefile  # macOS (BSD sed)
else
    sed -i "s/gram.c:/gram.c1:/" makefile  # Linux (GNU sed)
fi
make


mkdir -p $PREFIX/bin
cp f2c $PREFIX/bin
