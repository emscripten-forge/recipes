
# check if file src/Makevars exists, if not create exit with error
if [ ! -f src/Makevars ]; then
  echo "Error: src/Makevars file is missing. Please create an empty file at src/Makevars"
  exit 1
fi

# setup debug flags
export OPT_FLAG="-g -O0"

rm src/libpython.cpp
rm src/libpython.h


# show all shared libraries in $PREFIX/lib
echo "Shared libraries in $PREFIX/lib:"

# show all static libraries in $PREFIX/lib
echo "Static libraries in $PREFIX/lib:"
ls $PREFIX/lib/*.a

# remove shared ssl
rm -f $PREFIX/lib/libssl.so




echo "Building reticulate package.........."

$R CMD INSTALL $R_ARGS .
