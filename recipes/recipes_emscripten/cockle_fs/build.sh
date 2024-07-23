touch fs.c
emcc fs.c -o fs.js \
    -sALLOW_MEMORY_GROWTH=1 \
    -sENVIRONMENT=web,worker \
    -sEXPORTED_RUNTIME_METHODS=FS,PATH,ERRNO_CODES,PROXYFS \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -sSINGLE_FILE=1 \
    -lproxyfs.js


mkdir -p $PREFIX/bin
cp fs.js $PREFIX/bin/fs.js
