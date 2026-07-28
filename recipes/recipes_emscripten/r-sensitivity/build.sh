#!/bin/bash

echo "INSPECTING RcppParallel shared library for tbbParallelFor symbol"
nm -D $BUILD_PREFIX/lib/R/library/RcppParallel/libs/RcppParallel.so | grep tbbParallelFor



$R CMD INSTALL $R_ARGS .