#!/usr/bin/env bash
set -euxo pipefail

# ---------------------------------------------------------------------------
# OpenJDK 21 (Zero interpreter) for emscripten-wasm32, with AWT/Swing on top
# of x11.wasm. Produces static archives, a class-library image, and a small
# kit (launcher + link script) that turns them into a runnable wasm program.
# ---------------------------------------------------------------------------

JOBS="${CPU_COUNT:-4}"
CONF=emscripten-zero

BOOT_JDK="$BUILD_PREFIX/lib/jvm"          # conda-forge openjdk layout
[ -x "$BOOT_JDK/bin/javac" ] || BOOT_JDK="$BUILD_PREFIX"

EMSDK_SYSROOT="$(em-config CACHE)/sysroot"
EMSDK_LLVM_BIN="$(em-config LLVM_ROOT)"

WASM_NATIVE_DIR="$PREFIX/lib/wasm-native"
JDK_IMAGE_DIR="$PREFIX/jdk-wasm"
KIT_DIR="$PREFIX/share/openjdk21-wasm"
mkdir -p "$WASM_NATIVE_DIR" "$KIT_DIR" "$PREFIX/bin"

# Everything ends up in one shared-memory (pthreads) module, so every object,
# including third-party ones, must be compiled with atomics + bulk-memory.
THREAD_FLAGS="-pthread -sUSE_PTHREADS=1 -sSHARED_MEMORY=1"

# ---------------------------------------------------------------------------
# 1. libffi (Zero's call path for every native method), built with pthreads.
#    emscripten-forge's libffi package is not thread-enabled, so it cannot be
#    linked into this module. WASM_BIGINT must match -sWASM_BIGINT at link.
# ---------------------------------------------------------------------------
FFI_OUT="$SRC_DIR/libffi-install"
if [ ! -f "$FFI_OUT/lib/libffi.a" ]; then
  (
    cd "$SRC_DIR/libffi"
    emconfigure ./configure \
      --host=wasm32-unknown-linux \
      --prefix="$FFI_OUT" \
      --enable-static --disable-shared --disable-docs \
      --disable-multi-os-directory --disable-raw-api \
      --disable-dependency-tracking \
      CFLAGS="-O2 $THREAD_FLAGS -DWASM_BIGINT"
    emmake make -j"$JOBS"
    emmake make install
  )
fi
cp "$FFI_OUT/lib/libffi.a" "$WASM_NATIVE_DIR/libffi.a"

# ---------------------------------------------------------------------------
# 2. configure
#
# X11: the fork's configure turns X11 off for emscripten (NEEDS_LIB_X11=false,
# so --with-x is ignored and X_CFLAGS is empty), but java.desktop's natives
# still #include <X11/...>. The headers come from the x11-wasm host package;
# being a static build, nothing links against X11 here.
#
# Third-party libraries are all "bundled" so they are compiled with the flags
# above (pthread-compatible) and end up inside the JDK's own archives.
#
# JVM features: everything Zero can build on this port. compiler1/2, jvmci
# and zgc are unavailable for Zero, shenandoah is unavailable on wasm32, JFR
# needs os_perf support the port does not have, dtrace does not exist here.
# ---------------------------------------------------------------------------
JVM_FEATURES="zero,static-build,serialgc,epsilongc,parallelgc,g1gc,cds,jvmti,management,services,jni-check,vm-structs"

# CUPSfuncs.c and fontpath.c (compiled into libawt_xawt) need the CUPS and
# fontconfig headers even though both libraries are dlopen()ed at runtime --
# which fails here, so printing reports "no printers" and fonts come from
# lib/fontconfig.properties. Only those two header directories are exposed,
# not the rest of the (linux-64) build prefix.
EXTRA_INC="$SRC_DIR/extra-include"
mkdir -p "$EXTRA_INC"
cp -R "$BUILD_PREFIX/include/cups" "$EXTRA_INC/"
mkdir -p "$EXTRA_INC/fontconfig"
cp "$BUILD_PREFIX/include/fontconfig/fontconfig.h" "$EXTRA_INC/fontconfig/"

# OpenJDK's config.guess reports any Linux whose kernel name contains
# "microsoft" (WSL) as a Windows build machine -- it supports building Windows
# JDKs from WSL -- and configure then fails ("could not be imported"). Name the
# Linux build machine explicitly; on regular Linux this is what it guesses anyway.
BUILD_MACHINE=()
if [ "$(uname -s)" = Linux ]; then
  BUILD_MACHINE=(--build="$(uname -m)-pc-linux-gnu")
fi

CONFIGURE_ARGS=(
  --with-conf-name="$CONF"
  "${BUILD_MACHINE[@]}"
  --openjdk-target=wasm32-unknown-emscripten
  --with-boot-jdk="$BOOT_JDK"
  --with-toolchain-type=clang
  --with-jvm-variants=zero
  --with-jvm-features="$JVM_FEATURES"
  --disable-jvm-feature-jfr
  --disable-jvm-feature-jvmci
  --disable-jvm-feature-dtrace
  --disable-jvm-feature-compiler1
  --disable-jvm-feature-compiler2
  --disable-jvm-feature-shenandoahgc
  --disable-jvm-feature-zgc
  --enable-static-build
  --with-libffi="$FFI_OUT"
  --with-sysroot="$EMSDK_SYSROOT"
  --with-extra-cflags="$THREAD_FLAGS -D__EMSCRIPTEN__ -I$PREFIX/include -I$EXTRA_INC"
  --with-extra-cxxflags="$THREAD_FLAGS -D__EMSCRIPTEN__ -fwasm-exceptions -I$PREFIX/include -I$EXTRA_INC"
  --with-extra-ldflags="-pthread -sERROR_ON_UNDEFINED_SYMBOLS=0"
  --with-freetype=bundled
  --with-libjpeg=bundled
  --with-giflib=bundled
  --with-libpng=bundled
  --with-lcms=bundled
  --with-zlib=bundled
  --with-cups=no
  --disable-warnings-as-errors
  --with-debug-level=release
  --with-native-debug-symbols=none
  --disable-precompiled-headers
  --with-num-cores="$JOBS"
  CC=emcc CXX=em++ AR=emar
  NM="$EMSDK_LLVM_BIN/llvm-nm"
  STRIP="$EMSDK_LLVM_BIN/llvm-strip"
  OBJCOPY="$EMSDK_LLVM_BIN/llvm-objcopy"
  OBJDUMP="$EMSDK_LLVM_BIN/llvm-objdump"
  BUILD_CC=clang BUILD_CXX=clang++
)

# Re-running configure is only needed when its arguments change; this keeps
# iterative local builds incremental.
if [ ! -f "build/$CONF/spec.gmk" ] || \
   [ "$(cat "build/$CONF/.configure-args" 2>/dev/null)" != "${CONFIGURE_ARGS[*]}" ]; then
  bash configure "${CONFIGURE_ARGS[@]}"
  echo "${CONFIGURE_ARGS[*]}" > "build/$CONF/.configure-args"
fi
grep -E '^JVM_FEATURES_zero' "build/$CONF/spec.gmk" || true

# ---------------------------------------------------------------------------
# 3. build
# ---------------------------------------------------------------------------
make CONF="$CONF" buildtools copy gendata java JOBS="$JOBS"
make CONF="$CONF" hotspot JOBS="$JOBS"
make CONF="$CONF" static-libs-image JOBS="$JOBS"

# ---------------------------------------------------------------------------
# 4. static archives
# ---------------------------------------------------------------------------
B="build/$CONF"
find "$B/support/native" -path '*/static/*' -name 'lib*.a' -type f \
  -exec cp {} "$WASM_NATIVE_DIR/" \;
cp "$B/jdk/lib/zero/libjvm.a" "$WASM_NATIVE_DIR/"
ls -l "$WASM_NATIVE_DIR"

# ---------------------------------------------------------------------------
# 5. class library image, from this build's own classes
#
# The classes must come from this build, not the (linux-64) boot JDK: several
# are generated for the target -- the X11 struct wrappers (32-bit layouts),
# errno/open-flag constants (emscripten's errno numbers are not Linux's), and
# so on. The build has no jmod/jlink of its own for this target (and would
# otherwise build a second, native JDK for them), so the boot JDK's jmod packs
# each compiled module with its conf/legal/lib files and its jlink links them.
# Native libraries are not in the image; empty placeholders stand in for them
# because the JDK checks the files exist before resolving entry points from
# the static symbol table.
# ---------------------------------------------------------------------------
VERSION="$(sed -n 's/^VERSION_SHORT := //p' "$B/spec.gmk")"
S="$B/support"
STAGE="$SRC_DIR/wasm-jmods-stage"
JMODS="$SRC_DIR/wasm-jmods"
rm -rf "$STAGE" "$JMODS" "$JDK_IMAGE_DIR"
mkdir -p "$STAGE" "$JMODS"
for mdir in "$B"/jdk/modules/*/; do
  m=$(basename "$mdir")
  case $m in jdk.incubator.*) continue ;; esac   # need C2; would warn at startup
  cls="$STAGE/$m/classes"
  mkdir -p "$cls"
  cp -a "$mdir/." "$cls/"
  find "$cls" -name '_the.*' -delete              # build bookkeeping files
  # jlink knows no wasm32 target; the platform only has to be consistent
  args=(--class-path "$cls" --module-version "$VERSION" --target-platform linux-other)
  if [ -d "$S/modules_libs/$m" ]; then
    libs="$STAGE/$m/libs"
    mkdir -p "$libs"
    cp -a "$S/modules_libs/$m/." "$libs/"
    find "$libs" \( -name '*.a' -o -name '*.symbols' \) -delete
    args+=(--libs "$libs")
  fi
  [ -d "$S/modules_conf/$m" ] && args+=(--config "$S/modules_conf/$m")
  [ -d "$S/modules_legal/$m" ] && args+=(--legal-notices "$S/modules_legal/$m")
  "$BOOT_JDK/bin/jmod" create "${args[@]}" "$JMODS/$m.jmod"
done

"$BOOT_JDK/bin/jlink" \
  --module-path "$JMODS" \
  --add-modules ALL-MODULE-PATH \
  --output "$JDK_IMAGE_DIR" \
  --strip-debug \
  --no-man-pages \
  --no-header-files \
  --compress=zip-6

for a in "$WASM_NATIVE_DIR"/lib*.a; do
  n=$(basename "$a" .a)
  case $n in libjvm|libffi) continue ;; esac
  touch "$JDK_IMAGE_DIR/lib/$n.so"
done
mkdir -p "$JDK_IMAGE_DIR/lib/zero"
touch "$JDK_IMAGE_DIR/lib/zero/libjvm.so"

# Fonts: there is no fontconfig in the browser, so the JDK falls back to
# lib/fontconfig.properties and the fonts in lib/fonts.
mkdir -p "$JDK_IMAGE_DIR/lib/fonts"
cp "$SRC_DIR"/fonts/ttf/DejaVu{Sans,Sans-Bold,Sans-Oblique,Sans-BoldOblique,Serif,Serif-Bold,Serif-Italic,Serif-BoldItalic,SansMono,SansMono-Bold,SansMono-Oblique,SansMono-BoldOblique}.ttf \
  "$JDK_IMAGE_DIR/lib/fonts/"
cp "$SRC_DIR/fonts/LICENSE" "$JDK_IMAGE_DIR/lib/fonts/LICENSE-DejaVu"
cp "$RECIPE_DIR/kit/fontconfig.properties" "$JDK_IMAGE_DIR/lib/fontconfig.properties"

# ---------------------------------------------------------------------------
# 6. link kit: launcher, symbol-table generator, link script, page shell
# ---------------------------------------------------------------------------
cp "$RECIPE_DIR"/kit/{jvm-main.c,gen-symbols.sh,shell.html,serve.py,x11-display-share.c} "$KIT_DIR/"
mkdir -p "$KIT_DIR/include"
cp src/java.base/share/native/include/jni.h \
   src/java.base/unix/native/include/jni_md.h "$KIT_DIR/include/"
install -m 755 "$RECIPE_DIR/kit/openjdk21-wasm-link" "$PREFIX/bin/openjdk21-wasm-link"
