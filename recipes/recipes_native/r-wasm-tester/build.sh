#!/bin/bash

set -eux

mkdir -p $PREFIX/bin
cp $RECIPE_DIR/Rtester.js $PREFIX/bin/Rtester.js
cp $RECIPE_DIR/run_r_test.sh $PREFIX/bin/run_r_test

chmod +x $PREFIX/bin/run_r_test
