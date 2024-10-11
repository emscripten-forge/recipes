
# 1) git clone --depth 1 --branch v3.11 git://git.savannah.gnu.org/grep.git
# 2) cd grep
# 3) sudo apt update
# 4) sudo apt install -y autoconf autopoint gettext gperf pkg-config texinfo
# 5) ./bootstrap
# 6) emconfigure ./configure \
#       --disable-nls \
#       --disable-threads \
#       FORCE_UNSAFE_CONFIGURE=1 \
#       TIME_T_32_BIT_OK=yes \
#       ac_cv_have_decl_alarm=no \
#       gl_cv_func_sleep_works=yes
# 7) export CFLAGS="-O2 --minify=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=callMain,FS,ENV,getEnvStrings -sFORCE_FILESYSTEM=1 -sINVOKE_RUN=0 -sMODULARIZE=1 -sSINGLE_FILE=1 -sERROR_ON_UNDEFINED_SYMBOLS=0"
# 8) emmake make all CFLAGS="$CFLAGS" EXEEXT=.js -j4
#       It seems that it is important to pass the CFLAGS on the emmake line, not just have them stored
#       in an env var.  Need to tolerate all the warnings.
# 9) File needed is src/grep.js

git clone --depth 1 --branch v3.11 git://git.savannah.gnu.org/grep.git
cd grep

./bootstrap --skip-po
emconfigure ./configure \
      --disable-nls \
      --disable-threads \
      FORCE_UNSAFE_CONFIGURE=1 \
      TIME_T_32_BIT_OK=yes \
      ac_cv_have_decl_alarm=no \
      gl_cv_func_sleep_works=yes

export CFLAGS="-O2 --minify=0 -sALLOW_MEMORY_GROWTH=1 -sENVIRONMENT=web,worker -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY -sFORCE_FILESYSTEM=1 -sMODULARIZE=1 -sERROR_ON_UNDEFINED_SYMBOLS=0"
emmake make all CFLAGS="$CFLAGS" EXEEXT=.js

ls

mkdir -p $PREFIX/bin
cp src/grep.{js,wasm} $PREFIX/bin/
