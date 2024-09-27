#!/bin/bash

set -e

echo "R_HOME=\$(PREFIX)/lib/R" > $BUILD_PREFIX/lib/R/etc/Makeconf
cat $PREFIX/lib/R/etc/Makeconf >> $BUILD_PREFIX/lib/R/etc/Makeconf

$BUILD_PREFIX/bin/R CMD INSTALL . \
    --no-test-load --no-byte-compile --library=$PREFIX/lib/R/library