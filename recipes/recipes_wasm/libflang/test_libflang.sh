export LDFLAGS="-L$PREFIX/lib -lflang_rt.runtime"

# Intrinsic .mod files (iso_c_binding, etc.)
FINTRINSIC_MODS=$(echo "$PREFIX"/lib/clang/*/finclude/flang/"$TARGET_TRIPLE")
if [ ! -d "$FINTRINSIC_MODS" ]; then
    echo "intrinsic modules not found under $PREFIX/lib/clang/*/finclude/flang/$TARGET_TRIPLE"
    exit 1
fi

# -cpp enables __wasm32__/__wasm64__
flang $FFLAGS -cpp -fintrinsic-modules-path "$FINTRINSIC_MODS" -c ./hello.f90 -o hello.o
emcc hello.o $LDFLAGS -o hello.js -sEXIT_RUNTIME=1 -sMAIN_MODULE=1

# Copy the shared library to the current test directory if it exists
if [ -f $PREFIX/lib/libflang_rt.runtime.so ]; then
    cp $PREFIX/lib/libflang_rt.runtime.so .
fi

# TODO: This may be a real bug in upstream/emscripten
# Workaround wasm64 MAIN_MODULE callMain using raw main (missing envp → BigInt error).
# Minified JS uses "main"; unminified uses 'main'.
sed -i -E "s/resolveGlobalSymbol\(['\"]main['\"]\)\.sym/_main/" hello.js

node hello.js
