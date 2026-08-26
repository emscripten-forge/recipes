#!/usr/bin/env bash

set -eux

# R extension modules must not retain zlib as a separate wasm side module.
# Keep libz.a available, but remove shared candidates so -lz resolves static.
rm -f "$PREFIX"/lib/libz.so*
rm -f "$PREFIX"/lib/R/lib/libz.so*

R CMD INSTALL $R_ARGS .
