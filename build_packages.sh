#!/bin/bash
set -e

BUILD_NAME=$1
SKIP=$2
PKG_NAMES=($(python build_all_helper.py $BUILD_NAME 0 | tr -d '[],'))
FEATURES=($(python build_all_helper.py $BUILD_NAME 1 | tr -d '[],'))
BUILD_OR_HOST=($(python build_all_helper.py $BUILD_NAME 2 | tr -d '[],'))


for i in "${!PKG_NAMES[@]}"; do
    PKG_NAME=${PKG_NAMES[i]}
    FEATS=${FEATURES[i]}
    if [[ ${FEATS} == "-" ]]; then
        echo $PKG_NAME "NO FEAT"
        F=""
    else
        echo $PKG_NAME "FEATS" $FEATS
        F="--features [$FEATS]"
    fi

    if [[ ${BUILD_OR_HOST[i]} == "build" ]]; then
        boa build recipes/$PKG_NAME $F $SKIP
    else
        boa build recipes/$PKG_NAME --target-platform=emscripten-32  $F $SKIP
    fi
done