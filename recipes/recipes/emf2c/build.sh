#!/bin/bash

set -e

cd src

cp makefile.u makefile
sed -i "s/gram.c:/gram.c1:/" makefile
make


mkdir -p $PREFIX/bin
cp f2c $PREFIX/bin