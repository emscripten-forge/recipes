# Need tsc installed and available in PATH to use --emit-tsd
npm install typescript
export PATH=$SRC_DIR/node_modules/typescript/bin:$PATH

touch fs.c
emcc fs.c -o fs.js \
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES,PROXYFS \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    --emit-tsd fs.d.ts

mkdir -p $PREFIX/bin
cp fs.{d.ts,js,wasm} $PREFIX/bin/
