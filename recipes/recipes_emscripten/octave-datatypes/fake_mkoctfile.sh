#!/usr/bin/env bash
set -euxo pipefail

SOURCE_FILE=""

for arg in "$@"; do
    if [[ "$arg" == *.cc ]]; then
        SOURCE_FILE="$arg"
        break
    fi
done

if [[ -n "$SOURCE_FILE" ]]; then
    BASENAME=$(basename "$SOURCE_FILE" .cc)
    EXTRA_ARG="-o ${BASENAME}.oct"
else
    EXTRA_ARG=""
fi

emcc -sSIDE_MODULE=1 -O3 -I "$PREFIX/include/octave-${OCTAVE_VER}" "$@" $EXTRA_ARG
