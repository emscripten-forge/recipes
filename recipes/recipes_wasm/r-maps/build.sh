#!/bin/bash

set -eux

pushd src
    gcc -O2 -o Lmake Lmake.c
    gcc -O2 -o Gmake Gmake.c
    chmod +x Lmake Gmake
popd

$R CMD INSTALL $R_ARGS .