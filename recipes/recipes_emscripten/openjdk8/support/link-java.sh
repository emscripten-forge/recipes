#!/bin/bash
# link-java.sh -- link the WebAssembly OpenJDK runtime (openjdk8.js/openjdk8.wasm)
# from the relocatable objects produced by the OpenJDK build.
#
# usage: link-java.sh BUILD_DIR OUT_DIR
#   BUILD_DIR  OpenJDK build output (…/build/linux-wasm32-normal-zero-release)
#   OUT_DIR    where openjdk8.js, openjdk8.wasm and the runtime jar go
# environment: PREFIX (host prefix with x11-wasm, gthread-jspi, libffi,
#   freetype, zlib), SUPPORT (this directory), EMLINK_OPT (default -O2)
set -euo pipefail

BUILD=$(cd "$1" && pwd)
OUT=$2
SUPPORT=${SUPPORT:-$(cd "$(dirname "$0")" && pwd)}
PREFIX=${PREFIX:?PREFIX must point to the host prefix}
OPT=${EMLINK_OPT:--O2}
JRE=$BUILD/images/j2re-image
LIBDIR=$JRE/lib/wasm32
WORK=$BUILD/wasm-link
mkdir -p "$WORK" "$OUT"

# Libraries linked into the module, in link order (the first definition of
# a symbol that several libraries share wins, see below).  Not included:
#  - awt_headless (the X11 toolkit is used), jsig (signal chaining),
#    splashscreen (only loaded by the native launcher), java_crw_demo;
#  - jdwp/dt_socket (the debugger needs sockets), j2pkcs11/j2gss/j2pcsc
#    (they drive native PKCS#11/GSS/PC-SC libraries with dlopen) -- these
#    also define private helpers with clashing names;
#  - jawt (libawt_xawt already contains JAWT_GetAWT).
LIBS=(jvm jli java verify zip net nio awt awt_xawt fontmanager mlib_image lcms jpeg
      jsound jsoundalsa management instrument npt hprof jsdt unpack jaas_unix sunec)

objpath() {
  case $1 in
    jvm) echo "$LIBDIR/server/libjvm.so" ;;
    jli) echo "$LIBDIR/jli/libjli.so" ;;
    *) echo "$LIBDIR/lib$1.so" ;;
  esac
}

OBJS=()
SPECS=()
for l in "${LIBS[@]}"; do
  o=$(objpath "$l")
  if [ ! -f "$o" ]; then
    echo "link-java: missing $o" >&2
    exit 1
  fi
  OBJS+=("$o")
  case $l in
    # Only the JNI invocation/JVM interface of HotSpot is looked up by name.
    jvm) SPECS+=("jvm=$o:^(JNI_|JVM_|jio_|AsyncGetCallTrace)") ;;
    *)   SPECS+=("$l=$o") ;;
  esac
done

# ------------------------------------------------ runtime support (C/Java)
RT=$SUPPORT/runtime
CFLAGS_RT="$OPT -Wall -I$RT -I$PREFIX/include -I$PREFIX/include/gthread \
  -I$BUILD/jdk/include -I$BUILD/jdk/include/linux"
emcc $CFLAGS_RT -c "$RT/wasm_dl.c" -o "$WORK/wasm_dl.o"
emcc $CFLAGS_RT -c "$RT/wasm_x11glue.c" -o "$WORK/wasm_x11glue.o"
emcc $CFLAGS_RT -c "$RT/wasm_browser.c" -o "$WORK/wasm_browser.o"
emcc $CFLAGS_RT -c "$RT/wasm_misc.c" -o "$WORK/wasm_misc.o"
wasm-ld -r -o "$WORK/libwasmrt.o" "$WORK/wasm_browser.o"
SPECS+=("wasmrt=$WORK/libwasmrt.o")

# Java part of the runtime: fetch-based http(s), applet host, LiveConnect.
rm -rf "$WORK/rtclasses" && mkdir -p "$WORK/rtclasses"
"$JAVA_HOME_BUILD/bin/javac" -nowarn -source 8 -target 8 \
  -bootclasspath "$JRE/lib/rt.jar" -d "$WORK/rtclasses" \
  $(find "$SUPPORT/java/src" -name '*.java')
( cd "$WORK/rtclasses" && "$JAVA_HOME_BUILD/bin/jar" cf "$OUT/wasm-runtime.jar" . )

# ---------------------------------------------------- generated tables
python3 "$SUPPORT/wasm-dlsym-gen.py" -o "$WORK/dlsym_table.c" --list "$WORK/dlsym_table.txt" "${SPECS[@]}"
emcc $OPT -fno-builtin -Wno-incompatible-library-redeclaration -I"$RT" -c "$WORK/dlsym_table.c" -o "$WORK/dlsym_table.o"


# ------------------------------------------------------------- link
# x11-wasm: libX11.a (x11.wasm plus the stubs of the X extensions AWT
# references) is given by path -- emcc maps -lX11 to its own JavaScript
# stubs.  This is a single-threaded program (Java threads are JSPI green
# threads), so x11-wasm's pthreads.js and -sPROXY_TO_PTHREAD are not used;
# wasm_x11glue.c installs X11WasmSetHooks so that XNextEvent & co. wait
# for input by switching to other Java threads.
# Some sources are compiled into several JDK libraries (AWT initIDs/debug
# helpers, jio_snprintf, canonicalize, the per-library "JavaVM *jvm"
# variable).  The copies are identical, so the first definition is used.
EXPORTS='["_main","_malloc","_free","_gt_io_notify"]'
emcc $OPT -o "$OUT/openjdk8.js" \
  "$BUILD/jdk/objs/java_objs/main.o" "${OBJS[@]}" \
  "$WORK/libwasmrt.o" "$WORK/wasm_dl.o" "$WORK/wasm_x11glue.o" "$WORK/wasm_misc.o" \
  "$WORK/dlsym_table.o" \
  -L"$PREFIX/lib" "$PREFIX/lib/libX11.a" \
  -lfreetype -lz -lgthread-jspi "$PREFIX/lib/libffi.a" \
  --js-library "$PREFIX/share/x11-wasm/library.js" \
  --pre-js "$PREFIX/share/x11-wasm/dom.js" \
  --js-library "$PREFIX/share/gthread-jspi/gthread-library.js" \
  --js-library "$RT/wasmrt_lib.js" \
  --pre-js "$RT/java_pre.js" \
  -sJSPI -sJSPI_EXPORTS=gt_thread_entry,main \
  -sALLOW_MEMORY_GROWTH=1 -sINITIAL_MEMORY=64MB -sMAXIMUM_MEMORY=4GB \
  -sALLOW_TABLE_GROWTH=1 \
  -sSTACK_SIZE=2MB -sEXIT_RUNTIME=0 -sINVOKE_RUN=0 -sFORCE_FILESYSTEM=1 \
  -sMODULARIZE=1 -sEXPORT_NAME=createOpenJDK8Module -lnodefs.js \
  -sEXPORTED_FUNCTIONS="$EXPORTS" \
  -sEXPORTED_RUNTIME_METHODS='["FS","ENV","NODEFS","callMain","addRunDependency","removeRunDependency","UTF8ToString","stringToUTF8","lengthBytesUTF8"]' \
  -sERROR_ON_UNDEFINED_SYMBOLS=1 -sWASM_BIGINT=1 \
  -Wl,--allow-multiple-definition \
  ${EMLINK_EXTRA:-}
ls -la "$OUT"
