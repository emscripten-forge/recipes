#!/usr/bin/env bash

set -eux

# Force -lz to select libz.a, matching the established R recipe workaround.
rm -f "$PREFIX"/lib/libz.so*

R CMD INSTALL $R_ARGS .
