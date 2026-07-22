cp $RECIPE_DIR/patches/DESCRIPTION $SRC_DIR/DESCRIPTION

# replace THE_VERSION with $PACKAGE_VERSION in DESCRIPTION
sed -i.bak "s/THE_VERSION/${PACKAGE_VERSION}/g" $SRC_DIR/DESCRIPTION

# show the file contents of DESCRIPTION
cat $SRC_DIR/DESCRIPTION


cp $RECIPE_DIR/patches/tools_thread_emscripten.hpp $SRC_DIR/inst/include/vinecopulib/misc/tools_thread_emscripten.hpp
$R CMD INSTALL $R_ARGS .


