#!/bin/bash
set -eo pipefail

# GNU tar ships no configure script in git, generate it together with the
# gnulib/paxutils imports. --no-git: rattler-build has already checked out the
# gnulib and paxutils submodules.
./bootstrap --gnulib-srcdir=$PWD/gnulib --no-git

CONFIG_LDFLAGS="\
    -Os \
    --minify=0 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sEXIT_RUNTIME=1 \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,PROXYFS,TTY \
    -sFORCE_FILESYSTEM=1 \
    -sMODULARIZE=1 \
    -lproxyfs.js \
    -sSTACK_SIZE=1MB \
    "

emconfigure ./configure \
    --disable-acl \
    --disable-nls \
    --without-posix-acls \
    CFLAGS="$CFLAGS -Os" \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS"

# Emscripten's libc has no initgroups(3). tar only calls it when dropping
# privileges for a remote tape connection, which cannot happen here.
cat > initgroups-stub.c <<'EOF'
int initgroups (const char *user, int group) { (void) user; (void) group; return 0; }
EOF
emcc -c initgroups-stub.c -o "$PWD/initgroups-stub.o"

emmake make EXEEXT=.js -j${CPU_COUNT} \
    LDFLAGS="$LDFLAGS $CONFIG_LDFLAGS $PWD/initgroups-stub.o"

mkdir -p $PREFIX/bin
cp src/tar.{js,wasm} $PREFIX/bin/
