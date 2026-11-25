#!/bin/bash

set -eux

SHARE_DIR=$PREFIX/share/xeus-tester
mkdir -p $SHARE_DIR $PREFIX/bin

cp -r xeus-runner/dist_node $SHARE_DIR/dist_node
cp -r xeus-runner/dist_web $SHARE_DIR/dist_web
cp $RECIPE_DIR/xeus_tester.mjs $SHARE_DIR/xeus_tester.mjs
cp $RECIPE_DIR/index.html $SHARE_DIR/index.html

cp $RECIPE_DIR/xeus-tester.sh $PREFIX/bin/xeus-tester
chmod +x $PREFIX/bin/xeus-tester
