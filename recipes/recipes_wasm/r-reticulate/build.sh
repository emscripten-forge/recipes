#!/bin/bash

set -eux

# check if file src/Makevars exists, if not exit with error
if [ ! -f src/Makevars ]; then
  echo "Error: src/Makevars file is missing. Please create an empty file at src/Makevars"
  exit 1
fi

sed -i.bak "s/python3\.13/python${PY_VER}/g" src/Makevars
rm -f src/Makevars.bak

rm src/libpython.cpp
rm src/libpython.h

$R CMD INSTALL $R_ARGS .
