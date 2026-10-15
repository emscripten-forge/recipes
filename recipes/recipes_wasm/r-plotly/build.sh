#!/bin/bash

# replace __VERSION__ in DESCRIPTION with the version of the recipe
sed -i.bak "s/__VERSION__/${PKG_VERSION}/g" DESCRIPTION && rm -f DESCRIPTION.bak

cp $RECIPE_DIR/DESCRIPTION $SRC_DIR/DESCRIPTION

# copy NAMESPACE from recipe dir to source dir
cp $RECIPE_DIR/NAMESPACE $SRC_DIR/NAMESPACE


# remove certain files
rm $SRC_DIR/R/api_exports.R
rm $SRC_DIR/R/process.R
rm $SRC_DIR/R/orca.R


$R CMD INSTALL $R_ARGS .