#!/bin/bash

set -eux

sed -i 's|\$(R_HOME)/bin/R|\$(BUILD_PREFIX)/bin/R|g' \
    "${BUILD_PREFIX}/lib/R/share/make/shlib.mk"

export UserNM=llvm-nm

$R CMD INSTALL $R_ARGS .
