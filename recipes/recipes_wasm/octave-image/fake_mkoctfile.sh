#!/usr/bin/env bash
set -euxo pipefail

SOURCE_FILE="$1"

# if the first argument is -c
if [ "$SOURCE_FILE" == "-c" ]; then
    # second arg is filename
    SOURCE_FILE="$2"
    EXTRA_ARG=""
else
    SOURCE_FILE="$1"

    # get the basename without extension, e.g. "Gwatershed.cc" -> "Gwatershed"
    BASENAME=$(basename "$SOURCE_FILE" .cc)
    EXTRA_ARG=" -o ${BASENAME}.oct"
fi





emcc -sSIDE_MODULE=1 -O3 -I "$PREFIX/include/octave-${OCTAVE_VER}" "$@" $EXTRA_ARG