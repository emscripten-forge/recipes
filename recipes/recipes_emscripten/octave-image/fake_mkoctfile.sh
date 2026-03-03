#!/usr/bin/env bash
set -euxo pipefail

SOURCE_FILE="$1"
SOURCE_BASENAME=$(basename "$SOURCE_FILE" .cc)

if [[ "$@" != *"-c"* ]]; then
    EXTRA_ARG="-o ${SOURCE_BASENAME}.oct"
else
    EXTRA_ARG=""
fi
emcc -sSIDE_MODULE=1 -O3 -I "$PREFIX/include/octave-${OCTAVE_VER}" "$@" $EXTRA_ARG