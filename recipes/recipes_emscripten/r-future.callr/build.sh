#!/bin/bash


cp $RECIPE_DIR/CallrFutureBackend-class.R $SRC_DIR/R/CallrFutureBackend-class.R
cp $RECIPE_DIR/001.import_future_functions.R $SRC_DIR/R/001.import_future_functions.R


cp $RECIPE_DIR/DESCRIPTION $SRC_DIR/DESCRIPTION
cp $RECIPE_DIR/NAMESPACE $SRC_DIR/NAMESPACE


# replace __VERSION__ in DESCRIPTION with the version from recipe.yaml
sed -i.bak "s/__VERSION__/${PKG_VERSION}/g" $SRC_DIR/DESCRIPTION
rm $SRC_DIR/DESCRIPTION.bak

$R CMD INSTALL $R_ARGS .

