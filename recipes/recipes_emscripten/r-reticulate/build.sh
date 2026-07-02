#!/bin/bash

set -eux

# check if file src/Makevars exists, if not exit with error
if [ ! -f src/Makevars ]; then
  echo "Error: src/Makevars file is missing. Please create an empty file at src/Makevars"
  exit 1
fi

# setup debug flags
export OPT_FLAG="-g -O0"

rm -f src/libpython.cpp
rm -f src/libpython.h

# show all static libraries in $PREFIX/lib
echo "Static libraries in $PREFIX/lib:"
ls $PREFIX/lib/*.a

# remove shared ssl to force static linking
rm -f $PREFIX/lib/libssl.so

echo "Building reticulate package.........."

$R CMD INSTALL $R_ARGS .
