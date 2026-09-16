export LDFLAGS="-L$PREFIX/lib -lflang_rt.runtime"

if [ -z "$FINTRINSIC_MODS" ]; then
    echo "Flang did not set FINTRINSIC_MODS on activation"
    exit 1
fi

# -cpp enables __wasm32__/__wasm64__
flang $FFLAGS -cpp $FINTRINSIC_MODS -c ./test_fortran.f90 -o test_fortran.o
emcc test_fortran.o $LDFLAGS -o test_fortran.js -sEXIT_RUNTIME=1 -sMAIN_MODULE=1

# Copy the shared library to the current test directory if it exists
if [ -f $PREFIX/lib/libflang_rt.runtime.so ]; then
    cp $PREFIX/lib/libflang_rt.runtime.so .
fi

# TODO: This may be a real bug in upstream/emscripten
# Workaround wasm64 MAIN_MODULE callMain using raw main (missing envp → BigInt error).
# Minified JS uses "main"; unminified uses 'main'.
sed -i -E "s/resolveGlobalSymbol\(['\"]main['\"]\)\.sym/_main/" test_fortran.js

node test_fortran.js
