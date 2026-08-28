#!/bin/bash

set -eux

export R_HOME="${PREFIX}/lib/R"
export R_SHARE_DIR="${R_HOME}/share"

rm $PREFIX/lib/libz.so* || true
rm $PREFIX/lib/libssl.so* || true
rm $PREFIX/lib/libcrypto.so* || true

emmake make install
