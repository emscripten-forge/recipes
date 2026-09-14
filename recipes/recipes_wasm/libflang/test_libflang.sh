export LDFLAGS="-L$PREFIX/lib -lflang_rt.runtime"

# Test the library
flang $FFLAGS -c ./hello.f90 -o hello.o
emcc hello.o $LDFLAGS -o hello.js -sEXIT_RUNTIME=1 -sMAIN_MODULE=1

# Copy the shared library to the current test directory if it exists
if [ -f $PREFIX/lib/libflang_rt.runtime.so ]; then
    cp $PREFIX/lib/libflang_rt.runtime.so .
fi
node hello.js | grep -F "Hello, Fortran!"
