#!/bin/bash
set -euo pipefail

cd "${SRC_DIR}"

# The emscripten-forge compiler activation injects EMCC_CFLAGS with
# "-fwasm-exceptions -sSUPPORT_LONGJMP=wasm" (plus -msimd128 -fPIC) into every
# emcc call. The GC fix in step 4 relies on Binaryen's --flatten, which does
# not support wasm exception-handling instructions, so use Emscripten's
# JS-based setjmp/longjmp instead. ruby18 is a standalone program, not a side
# module, so this does not affect compatibility with other packages.
export EMCC_CFLAGS="-O2 -g0"

HOST_SRC="${BUILD_DIR:-${SRC_DIR}/..}/ruby18-host-src"
HOST_PREFIX="${BUILD_DIR:-${SRC_DIR}/..}/ruby18-host"
JOBS="${CPU_COUNT:-2}"

# Old K&R C. Keep modern compilers from turning these into hard errors.
QUIET="-Wno-deprecated-non-prototype -Wno-parentheses -Wno-dangling-else \
 -Wno-unused-value -Wno-pointer-sign -Wno-compare-distinct-pointer-types \
 -Wno-shift-negative-value -Wno-comment -Wno-string-plus-int -Wno-unused-result \
 -Wno-incompatible-function-pointer-types -Wno-implicit-function-declaration \
 -Wno-int-conversion -Wno-incompatible-pointer-types -Wno-implicit-int -Wno-return-type"

config_sub_dir() {
    for d in "${BUILD_PREFIX}"/share/automake-* /usr/share/automake-* /usr/share/misc; do
        if [ -f "$d/config.sub" ]; then echo "$d"; return; fi
    done
    echo "no modern config.sub found" >&2
    exit 1
}
CONFIG_SUB_DIR="$(config_sub_dir)"

###############################################################################
# 1. Native host Ruby 1.8.7
#
# When cross compiling, Ruby 1.8's Makefile runs mkconfig.rb and ext/extmk.rb
# with "ruby -rfake", which must be the same Ruby version.
###############################################################################

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

###############################################################################
# 2. Cross build for wasm32-unknown-emscripten
###############################################################################

cp "${CONFIG_SUB_DIR}/config.sub" "${CONFIG_SUB_DIR}/config.guess" .
chmod +x config.sub config.guess

cat > config.cache <<'EOF'
ac_cv_func_setpgrp_void=yes
ac_cv_func_getpgrp_void=yes
rb_cv_stack_grow_dir=-1
EOF

# -fgnu89-inline: lex.c (gperf) relies on GNU89 inline semantics.
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
# wasm-main.c: main() that lowers Ruby's stack limit so runaway recursion
# raises SystemStackError before the JS engine's call stack is exhausted.
emcc ${CFLAGS_T} -I. -DRUBY_WASM_STACK_DEFAULT=655360 -c "${RECIPE_DIR}/wasm-main.c" -o wasm-main.o
emcc ${CFLAGS_T} -I. -c "${RECIPE_DIR}/extinit.c" -o extinit.o

###############################################################################
# 3. Link
#
# EMULATE_FUNCTION_POINTER_CASTS: Ruby 1.8 registers C methods and callbacks
# through unprototyped function pointers whose arity does not always match the
# definition (e.g. rb_obj_dummy registered with arity 1); wasm traps on such
# indirect calls otherwise.
#
# --profiling-funcs keeps the name section so the GC step below can find
# __stack_pointer. It is stripped again afterwards.
###############################################################################

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
    -sEXPORTED_RUNTIME_METHODS=FS,ENV,getEnvStrings,TTY,callMain

###############################################################################
# 4. Make the conservative GC sound on wasm
#
# Ruby 1.8's GC finds live objects by scanning the C stack. On wasm most C
# locals live in wasm locals or on the wasm value stack, which a scan of
# linear memory cannot see, so objects still in use get collected.
#   --flatten         every intermediate value becomes a local
#   --spill-pointers  every i32 local live across a call is stored to a slot
#                     on the shadow stack, which gc.c already scans
###############################################################################

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

###############################################################################
# 5. Install
###############################################################################

mkdir -p "${PREFIX}/bin"
install -m755 ruby.js "${PREFIX}/bin/ruby.js"
install -m644 ruby.wasm "${PREFIX}/bin/ruby.wasm"

RUBYLIBDIR="${PREFIX}/lib/ruby/1.8"
mkdir -p "${RUBYLIBDIR}/wasm32-emscripten"
cp -r lib/* "${RUBYLIBDIR}/"
cp -r .ext/common/* "${RUBYLIBDIR}/"
cp rbconfig.rb "${RUBYLIBDIR}/wasm32-emscripten/"
