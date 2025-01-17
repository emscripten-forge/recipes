echo "Building GMP"



filename=Makefile.in

# Check the operating system
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    sed -i '' 's#\./gen-#node ./gen-#g' "$filename"
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    sed -i 's#\./gen-#node ./gen-#g' "$filename"
else
    echo "Unsupported OS: $OSTYPE"
    exit 1
fi






echo "Building GMP Step 1"
CC_FOR_BUILD=emcc CPP_FOR_BUILD=emcc HOST_CC=emcc  emconfigure ./configure \
    CFLAGS="$CFLAGS -fPIC" \
    --prefix=${PREFIX}  \
    --disable-assembly  \
    --enable-cxx \
    --host=none \
    # --enable-fat

emmake make -j${CPU_COUNT}
emmake make install
