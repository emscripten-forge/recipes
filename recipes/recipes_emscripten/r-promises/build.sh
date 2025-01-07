#!/bin/bash

set -ex

# FIXME: Rcpp has a patch, but this gets overwritten by the activation script of
# cross-r-base. We need to copy it again here.
cp $RECIPE_DIR/patches/exceptions_impl.h $PREFIX/lib/R/library/Rcpp/include/Rcpp/

$R CMD INSTALL $R_ARGS --no-byte-compile .