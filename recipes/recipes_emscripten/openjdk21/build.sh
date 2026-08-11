#!/usr/bin/env bash
set -euo pipefail

EMSDK_SYSROOT="$(em-config EMSCRIPTEN_ROOT)/cache/sysroot"
EMSDK_LLVM_BIN="$(em-config LLVM_ROOT)"

BOOT_JDK="$BUILD_PREFIX"

bash configure \
  --with-conf-name=emscripten-zero \
  --openjdk-target=wasm32-unknown-emscripten \
  --with-boot-jdk="$BOOT_JDK" \
  --with-toolchain-type=clang \
  --with-jvm-variants=zero \
  --with-jvm-features=zero,serialgc,static-build \
  --disable-jvm-feature-g1gc \
  --disable-jvm-feature-parallelgc \
  --disable-jvm-feature-shenandoahgc \
  --disable-jvm-feature-zgc \
  --disable-jvm-feature-epsilongc \
  --disable-jvm-feature-jfr \
  --disable-jvm-feature-jvmci \
  --disable-jvm-feature-dtrace \
  --disable-jvm-feature-compiler1 \
  --disable-jvm-feature-compiler2 \
  --enable-jvm-feature-zero \
  --enable-jvm-feature-serialgc \
  --enable-jvm-feature-static-build \
  --enable-static-build \
  --with-libffi="$PREFIX" \
  --with-sysroot="$EMSDK_SYSROOT" \
  --with-extra-cflags="-pthread -sUSE_PTHREADS=1 -sSHARED_MEMORY=1 -D__EMSCRIPTEN__" \
  --with-extra-cxxflags="-pthread -sUSE_PTHREADS=1 -sSHARED_MEMORY=1 -D__EMSCRIPTEN__ -fwasm-exceptions" \
  --with-extra-ldflags="-pthread -sERROR_ON_UNDEFINED_SYMBOLS=0" \
  --disable-warnings-as-errors \
  --with-debug-level=release \
  --with-native-debug-symbols=none \
  --disable-precompiled-headers \
  --with-x=yes \
  --with-cups=no \
  --with-alsa=no \
  --with-fontconfig=yes \
  --with-num-cores="${CPU_COUNT:-4}" \
  CC=emcc CXX=em++ AR=emar \
  NM="$EMSDK_LLVM_BIN/llvm-nm" \
  STRIP="$EMSDK_LLVM_BIN/llvm-strip" \
  OBJCOPY="$EMSDK_LLVM_BIN/llvm-objcopy" \
  OBJDUMP="$EMSDK_LLVM_BIN/llvm-objdump" \
  BUILD_CC=clang BUILD_CXX=clang++

make CONF=emscripten-zero static-libs-image JOBS="${CPU_COUNT:-4}"
make CONF=emscripten-zero hotspot JOBS="${CPU_COUNT:-4}"
make CONF=emscripten-zero buildtools copy java JOBS="${CPU_COUNT:-4}"

WASM_NATIVE_DIR="$PREFIX/lib/wasm-native"
mkdir -p "$WASM_NATIVE_DIR"
STATIC_LIBS_LIB_DIR="build/emscripten-zero/support/native"

find "$STATIC_LIBS_LIB_DIR" -name "*.a" -type f -exec cp {} "$WASM_NATIVE_DIR/" \;
cp build/emscripten-zero/jdk/lib/zero/libjvm.a "$WASM_NATIVE_DIR/"

JLINK="$BOOT_JDK/bin/jlink"
JDK_IMAGE_DIR="$PREFIX/jdk-wasm"

$JLINK \
  --add-modules ALL-MODULE-PATH \
  --output "$JDK_IMAGE_DIR" \
  --strip-debug \
  --no-man-pages \
  --no-header-files \
  --compress=2

# Remove native executables
find "$JDK_IMAGE_DIR/bin" -type f -exec rm {} \; 2>/dev/null || true

find "$JDK_IMAGE_DIR/lib" \( -name "*.so" -o -name "*.dylib" \) -type f | while read -r libpath; do
  libname=$(basename "$libpath")
  libdir=$(dirname "$libpath")
  
  base="${libname%.*}"
  
  rm "$libpath" 
  
  touch "$libdir/$base.so"
done
