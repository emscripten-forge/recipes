#!/bin/bash

echo "lets go"
ls 
./bootstrap --skip-po
emconfigure ./configure \
      --enable-single-binary \
      --disable-nls \
      --disable-threads \
      FORCE_UNSAFE_CONFIGURE=1 \
      TIME_T_32_BIT_OK=yes \
      ac_cv_have_decl_alarm=no \
      gl_cv_func_sleep_works=yes


echo "sed"      
sed -i 's|$(MAKE) src/make-prime-list$(EXEEXT)|gcc src/make-prime-list.c -o src/make-prime-list$(EXEEXT) -Ilib/|' Makefile
export CFLAGS="-O2 --minify=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker,node -sEXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings -sFORCE_FILESYSTEM=1 -sINVOKE_RUN=0 -sMODULARIZE=1 -sSINGLE_FILE=1"

make EXEEXT=.js CFLAGS="$CFLAGS" -k -j4 || true


ls
ls src/coreutils.js

mkdir -p $PREFIX/bin
cp src/coreutils.js $PREFIX/bin/coreutils.js
