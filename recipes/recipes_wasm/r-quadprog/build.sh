#!/bin/bash

set -eux



cp $RECIPE_DIR/Makevars $SRC_DIR/src/Makevars

$R CMD INSTALL $R_ARGS .