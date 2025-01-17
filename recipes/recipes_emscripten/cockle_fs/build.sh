touch fs.c
emcc fs.c -o fs.js \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES,PROXYFS \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js

mkdir -p $PREFIX/bin
cp fs.{js,wasm} $PREFIX/bin/
