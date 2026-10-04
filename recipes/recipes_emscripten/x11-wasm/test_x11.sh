#!/usr/bin/env bash
# Compiles a program against every X11 header OpenJDK's AWT uses and links it
# with x11.wasm the way a threaded (PROXY_TO_PTHREAD) program does. Running it
# needs a browser DOM, so the test stops at a successful link.
set -euxo pipefail
X="$PREFIX/share/x11-wasm"
emcc -pthread -O1 -I"$PREFIX/include" tests/awt_headers.c \
  "$PREFIX"/lib/lib{X11,Xext,Xrender,Xtst,Xi}.a \
  --js-library "$X/library.js" --pre-js "$X/dom.js" --pre-js "$X/pthreads.js" \
  -sPROXY_TO_PTHREAD=1 -sEXPORTED_FUNCTIONS=_main,_malloc,_free \
  -o awt_headers.js
test -s awt_headers.wasm
node --check "$X/library.js"
node --check "$X/dom.js"
node --check "$X/pthreads.js"
