#!/usr/bin/env bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# 1. x11.wasm: Xlib implemented on top of browser canvases
# ---------------------------------------------------------------------------
cd "$SRC_DIR/x11.wasm"

# Run the DOM-backed js-library functions on the browser main thread when they
# are called from a pthread (every Java thread is a Web Worker).
python3 "$RECIPE_DIR/add_proxy.py" js/emscripten/library/*.js

# The backend reads canvases back (getImageData) to implement raster ops and
# XGetImage; ask for CPU-backed 2D contexts so those readbacks do not stall on
# the GPU (Chrome warns about exactly this otherwise).
sed -i 's/getContext("2d")/getContext("2d", { willReadFrequently: true })/g' js/browser/dom/*.js

# XlibWasm.h (pulled in by Xlib.h) defines a bare EXTERN macro, which real
# Xlib does not; it breaks code that uses EXTERN as a token, such as
# OpenJDK's OGL_EXPRESS_ALL_FUNCS(EXTERN). Only that header uses it.
sed -i 's/\bEXTERN\b/X11WASM_EXTERN/g' include/X11/XlibWasm.h

# x11.wasm's ninja compile rule has no -pthread, but OpenJDK links with shared
# memory, so every object has to be built with atomics/bulk-memory.
# emcc appends EMCC_CFLAGS to every invocation.
export EMCC_CFLAGS="-pthread -O2 ${EMCC_CFLAGS:-}"
ninja -f build.ninja x11wasm_lib x11wasm_js

# x11.wasm keeps its state in plain globals (errorHandler, eventQueue,
# atomList, ...). Linked into a large program those names collide -- OpenJDK's
# liblcms has its own errorHandler. Rebuild with every global outside the
# Xlib / x11.wasm namespaces renamed to x11wasm_<name>. (ckalloc/ckfree are
# guarded by #ifndef in a public header, so they keep their names.)
NM="$(em-config LLVM_ROOT)/llvm-nm"
"$NM" --defined-only -g build/emscripten/libx11wasm.a 2>/dev/null \
  | awk 'NF == 3 { print $3 }' \
  | grep -v -E '^(X|_X|Browser|X11Wasm|x11wasm|ck)' | sort -u > private-globals.txt
echo "renaming $(wc -l < private-globals.txt) private globals"
RENAMES="$(sed 's/.*/-D&=x11wasm_&/' private-globals.txt | tr '\n' ' ')"
ninja -f build.ninja -t clean >/dev/null
EMCC_CFLAGS="$EMCC_CFLAGS $RENAMES" ninja -f build.ninja x11wasm_lib x11wasm_js
if "$NM" --defined-only -g build/emscripten/libx11wasm.a 2>/dev/null \
     | awk 'NF == 3 { print $3 }' | grep -q -x -F -f private-globals.txt; then
  echo "private globals were not renamed" >&2
  exit 1
fi

B="$SRC_DIR/x11.wasm/build/emscripten"
mkdir -p "$PREFIX/lib" "$PREFIX/include" "$PREFIX/share/x11-wasm"
cp -R include/X11 include/X11Wasm "$PREFIX/include/"
cp "$B/libx11wasm.a"               "$PREFIX/lib/libX11.a"
cp "$B/js/emscripten/library.js"   "$PREFIX/share/x11-wasm/library.js"
cp "$B/js/browser/dom.js"          "$PREFIX/share/x11-wasm/dom.js"
cp "$RECIPE_DIR/x11wasm-pthreads.js" "$PREFIX/share/x11-wasm/pthreads.js"

# ---------------------------------------------------------------------------
# 2. Upstream Xorg headers that x11.wasm does not ship (protocol headers and
#    the extension client headers AWT includes). x11.wasm's own headers are
#    never replaced.
# ---------------------------------------------------------------------------
copy_missing() {   # copy_missing <include-root> <relative-header>...
  local root=$1; shift
  local rel dest
  for rel in "$@"; do
    dest="$PREFIX/include/$rel"
    [ -e "$dest" ] && continue
    mkdir -p "$(dirname "$dest")"
    cp "$root/$rel" "$dest"
  done
}

X="$SRC_DIR/xorg"
( cd "$X/xorgproto/include" && find X11 -name '*.h' ) > proto-headers.txt
while read -r rel; do copy_missing "$X/xorgproto/include" "$rel"; done < proto-headers.txt

copy_missing "$X/libX11/include"     X11/XKBlib.h
copy_missing "$X/libXext/include"    X11/extensions/Xext.h \
                                     X11/extensions/shape.h \
                                     X11/extensions/XShm.h \
                                     X11/extensions/Xdbe.h \
                                     X11/extensions/xtestext1.h
copy_missing "$X/libXrender/include" X11/extensions/Xrender.h
copy_missing "$X/libXtst/include"    X11/extensions/XTest.h
copy_missing "$X/libXi/include"      X11/extensions/XInput.h
copy_missing "$X/libXrandr/include"  X11/extensions/Xrandr.h

# ---------------------------------------------------------------------------
# 3. Link stubs for extensions x11.wasm does not implement (SHAPE, MIT-SHM,
#    DBE, RENDER, XTEST, XInput, XKB). Their query functions answer "absent",
#    matching x11.wasm's XQueryExtension, so AWT uses core-X11 paths.
#    The stub object goes into libX11.a so that archive alone links;
#    libXext/libXrender/libXtst/libXi carry the same object for build systems
#    that name those libraries. Pass the archives by path: emcc maps -lX11
#    to its own small JS Xlib instead of this one.
# ---------------------------------------------------------------------------
emcc -pthread -O2 -c "$RECIPE_DIR/x11ext_stubs.c" -I"$PREFIX/include" -o x11ext_stubs.o
emar rcs "$PREFIX/lib/libX11.a" x11ext_stubs.o
for l in Xext Xrender Xtst Xi; do
  rm -f "$PREFIX/lib/lib$l.a"
  emar rcs "$PREFIX/lib/lib$l.a" x11ext_stubs.o
done

# Flags a final program needs to use x11.wasm (read by consumers' link steps).
# pthreads.js keeps DOM input from racing Xlib calls made on worker threads.
# The archive is named by path: emcc turns -lX11 into its own small JS Xlib.
cat > "$PREFIX/share/x11-wasm/link-flags.txt" <<EOF
$PREFIX/lib/libX11.a --js-library $PREFIX/share/x11-wasm/library.js --pre-js $PREFIX/share/x11-wasm/dom.js --pre-js $PREFIX/share/x11-wasm/pthreads.js -pthread -sPROXY_TO_PTHREAD=1 -sEXPORTED_FUNCTIONS=_main,_malloc,_free
EOF
