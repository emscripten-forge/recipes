
#!/bin/bash

set -eux


# the file dummy.c is part of the r-png sources
# the files looks like:
#
#   /* dummy symbols to keep superfluous CRAN checks happy
#      (this package uses NAMESPACE C-level symbol registration
#      but the checks don't get that) */

#   extern void R_registerRoutines(void);
#   extern void R_useDynamicSymbols(void);

#   void dummy(void) {
#       R_registerRoutines();
#       R_useDynamicSymbols();
#   }
# 
# but this gives:
#
#    wasm-ld: error: function signature mismatch: R_useDynamicSymbols
#     │ │ >>> defined as () -> void in dummy.o
#     │ │ >>> defined as (i32, i32) -> i32 in $PREFIX/lib/R/lib/libR.so
#     │ │ wasm-ld: error: function signature mismatch: R_registerRoutines
#     │ │ >>> defined as () -> void in dummy.o
#     │ │ >>> defined as (i32, i32, i32, i32, i32) -> i32 in $PREFIX/lib/R/lib/libR.so
#
# therefore we just delete it :)
rm src/dummy.c

# delete shared libz (this forces static linking of zlib)
rm -f $PREFIX/lib/R/lib/libz.so

# the file "NAMESPACE" looks like
#
#    useDynLib(png, write_png, read_png)
#    exportPattern(".*PNG")
#
# but we do not use a shared libpng
rm -f NAMESPACE
cp $RECIPE_DIR/NAMESPACE .



R CMD INSTALL $R_ARGS .