#!/bin/bash

echo "R_HOME=${BUILD_PREFIX}/lib/R" > "${BUILD_PREFIX}/lib/R/etc/Makeconf"
cat "${PREFIX}/lib/R/etc/Makeconf" >> "${BUILD_PREFIX}/lib/R/etc/Makeconf"

export R="${BUILD_PREFIX}/bin/R"
export R_ARGS="--no-byte-compile --no-test-load --library=$PREFIX/lib/R/library"