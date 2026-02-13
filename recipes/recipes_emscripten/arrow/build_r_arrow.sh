#!/bin/bash

# ============================================================================
# Build R Arrow Bindings
# ============================================================================

export ARROW_HOME=${PREFIX}
export LD_LIBRARY_PATH=${PREFIX}/lib:$LD_LIBRARY_PATH

cd $SRC_DIR/r
$R CMD INSTALL $R_ARGS .
