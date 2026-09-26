#!/bin/bash
set -euo pipefail

cd "${SRC_DIR}"

# --flatten (below) does not support wasm exception handling: use JS setjmp/longjmp.
export EMCC_CFLAGS="-O2 -g0"

HOST_SRC="${BUILD_DIR:-${SRC_DIR}/..}/ruby18-host-src"
HOST_PREFIX="${BUILD_DIR:-${SRC_DIR}/..}/ruby18-host"
JOBS="${CPU_COUNT:-2}"

QUIET="-Wno-deprecated-non-prototype -Wno-parentheses -Wno-dangling-else \
 -Wno-unused-value -Wno-pointer-sign -Wno-compare-distinct-pointer-types \
 -Wno-shift-negative-value -Wno-comment -Wno-string-plus-int -Wno-unused-result \
 -Wno-incompatible-function-pointer-types -Wno-implicit-function-declaration \
 -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-implicit-int -Wno-return-type"

config_sub_dir() {
    for d in "${BUILD_PREFIX}"/share/automake-*; do
        if [ -f "$d/config.sub" ]; then echo "$d"; return; fi
    done
    echo "no modern config.sub found" >&2
    exit 1
}
CONFIG_SUB_DIR="$(config_sub_dir)"

# Native host ruby 1.8.7, needed to cross compile
rm -rf "${HOST_SRC}" "${HOST_PREFIX}"
cp -a "${SRC_DIR}" "${HOST_SRC}"
(
    cd "${HOST_SRC}"
    cp "${CONFIG_SUB_DIR}/config.sub" "${CONFIG_SUB_DIR}/config.guess" .
    env -u CFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS \
        CC="${CC_FOR_BUILD:-gcc}" \
        CFLAGS="-O2 -std=gnu89 -fno-tree-dce -fno-optimize-sibling-calls -fpermissive -w" \
        ./configure \
            --prefix="${HOST_PREFIX}" \
            --disable-pthread \
            --disable-install-doc
    printf 'option nodynamic\netc\nstringio\nstrscan\nthread\ndigest\ndigest/md5\n' > ext/Setup
    env -u CFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS make -j"${JOBS}"
    env -u CFLAGS -u CPPFLAGS -u LDFLAGS -u LIBS make install
)
"${HOST_PREFIX}/bin/ruby" -v

# Cross build
cp "${CONFIG_SUB_DIR}/config.sub" "${CONFIG_SUB_DIR}/config.guess" .
chmod +x config.sub config.guess

cat > config.cache <<'EOF'
ac_cv_func_setpgrp_void=yes
ac_cv_func_getpgrp_void=yes
rb_cv_stack_grow_dir=-1
EOF

emconfigure ./configure \
    --cache-file=config.cache \
    --host=wasm32-unknown-emscripten \
    --build="$(./config.guess)" \
    --prefix="${PREFIX}" \
    --disable-pthread \
    --disable-install-doc \
    --with-static-linked-ext \
    RUBY="${HOST_PREFIX}/bin/ruby" \
    CFLAGS="-O2 -fgnu89-inline ${QUIET}"

cat > ext/Setup <<'EOF'
option nodynamic
iconv
stringio
socket
etc
fcntl
thread
strscan
digest
digest/md5
EOF

emmake make -j"${JOBS}"

CFLAGS_T="$(sed -n 's/^CFLAGS *= *//p' Makefile | sed 's/\${cflags}//')"
emcc ${CFLAGS_T} -I. -DRUBY_WASM_STACK_DEFAULT=655360 -c "${RECIPE_DIR}/wasm-main.c" -o wasm-main.o
emcc ${CFLAGS_T} -I. -c "${RECIPE_DIR}/extinit.c" -o extinit.o

# Full stdlib is installed; a subset is embedded for standalone web use.
STDLIB_MIN="${SRC_DIR}/stdlib-min"
rm -rf "${STDLIB_MIN}" "${SRC_DIR}/stdlib-full"
mkdir -p "${STDLIB_MIN}" "${SRC_DIR}/stdlib-full/wasm32-emscripten"
cp -r lib/* "${SRC_DIR}/stdlib-full/"
cp -r .ext/common/* "${SRC_DIR}/stdlib-full/"
cp rbconfig.rb "${SRC_DIR}/stdlib-full/wasm32-emscripten/"
(
    cd "${SRC_DIR}/stdlib-full"
    cp -r --parents \
        English.rb cgi.rb date.rb date delegate.rb digest.rb fileutils.rb ftools.rb \
        net/http.rb net/protocol.rb open-uri.rb optparse.rb optparse ostruct.rb \
        parsedate.rb rational.rb tempfile.rb thread.rb time.rb timeout.rb tmpdir.rb \
        uri.rb uri set.rb pp.rb prettyprint.rb shellwords.rb find.rb erb.rb \
        base64.rb benchmark.rb md5.rb singleton.rb forwardable.rb observer.rb \
        abbrev.rb getoptlong.rb pathname.rb wasm32-emscripten/rbconfig.rb \
        "${STDLIB_MIN}/"
)

emcc wasm-main.o extinit.o \
    ext/iconv/iconv.a ext/stringio/stringio.a ext/socket/socket.a \
    ext/etc/etc.a ext/fcntl/fcntl.a ext/thread/thread.a \
    ext/strscan/strscan.a ext/digest/digest.a ext/digest/md5/md5.a \
    libruby-static.a \
    -o ruby.js \
    -O1 \
    --profiling-funcs \
    -sEMULATE_FUNCTION_POINTER_CASTS=1 \
    -sALLOW_MEMORY_GROWTH=1 \
    -sSTACK_SIZE=8MB \
    -sFORCE_FILESYSTEM=1 \
    -sEXIT_RUNTIME=1 \
    -sMODULARIZE=1 \
    -sEXPORT_NAME=createRuby \
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY,callMain \
    -lworkerfs.js \
    --embed-file "${STDLIB_MIN}@/usr/local/lib/ruby/1.8"

# Spill live locals to the shadow stack so Ruby's conservative GC can see them.
WASM_OPT="$(em-config BINARYEN_ROOT 2>/dev/null || true)/bin/wasm-opt"
if [ ! -x "${WASM_OPT}" ]; then
    WASM_OPT="$(dirname "$(command -v emcc)")/../bin/wasm-opt"
fi
"${WASM_OPT}" ruby.wasm \
    --enable-bulk-memory --enable-nontrapping-float-to-int \
    --enable-sign-ext --enable-mutable-globals \
    -O2 --flatten --simplify-locals-nonesting --coalesce-locals \
    --spill-pointers -O2 \
    --strip-debug --strip-producers \
    -o ruby.wasm

mkdir -p "${PREFIX}/bin"
install -m755 ruby.js "${PREFIX}/bin/ruby.js"
install -m644 ruby.wasm "${PREFIX}/bin/ruby.wasm"

mkdir -p "${PREFIX}/lib/ruby/1.8"
cp -r "${SRC_DIR}/stdlib-full/." "${PREFIX}/lib/ruby/1.8/"
