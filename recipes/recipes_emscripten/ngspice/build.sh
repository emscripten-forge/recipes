#!/bin/bash

set -x
set -e

# Used by autotools AX_PROG_CC_FOR_BUILD
export CC_FOR_BUILD=${CC}

./autogen.sh

configure_args=(
  --prefix=${PREFIX}
  --disable-debug
  --disable-dependency-tracking
)

emconfigure ./configure "${configure_args[@]}" --with-ngshared LDFLAGS="${LDFLAGS}"
emmake make -j${CPU_COUNT}
emmake make install
