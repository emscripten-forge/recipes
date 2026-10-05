#!/bin/bash
# OpenJDK 8 (HotSpot Zero) for emscripten-wasm32.
#
# 1. configure + "make images" with the emjdk-cc compiler wrapper: every JDK
#    native library becomes a relocatable WebAssembly object.
# 2. link-java.sh links the libraries, the browser runtime (fetch, Web Audio,
#    LiveConnect, x11.wasm glue) and the cooperative thread library into one
#    module: openjdk8.js + openjdk8.wasm.
# 3. stage-jre.sh + pack-jre.py turn the JRE image into openjdk8-jre.json/openjdk8-jre.data.gz,
#    which openjdk8.js loads into its in-memory file system.
set -euxo pipefail

# The build machine's Java settings must not leak into the boot JDK.
unset JAVA_TOOL_OPTIONS _JAVA_OPTIONS CLASSPATH JAVA_HOME || true

SUPPORT="${RECIPE_DIR}/support"
BOOT_JDK="${BUILD_PREFIX}"          # conda-forge openjdk 8
JOBS="${CPU_COUNT:-2}"
TOOLS="${SRC_DIR}/_emjdk"
JDK_UPDATE="${PKG_VERSION##*.}"     # 8.0.504 -> 504
JDK_BUILD="${JDK_BUILD:-b01}"       # jdk8u504-ga == jdk8u504-b01

mkdir -p "${TOOLS}/bin" "${TOOLS}/freetype"
install -m 755 "${SUPPORT}/emjdk-cc" "${TOOLS}/bin/emjdk-cc"
ln -sf emjdk-cc "${TOOLS}/bin/emjdk-c++"
export PATH="${TOOLS}/bin:${PATH}"
# configure test programs are linked for real
export EMJDK_LDFLAGS="-L${PREFIX}/lib"
# configure looks for libfreetype.so; the static library is what gets linked
ln -sf "${PREFIX}/lib/libfreetype.a" "${TOOLS}/freetype/libfreetype.so"
ln -sf "${PREFIX}/lib/libfreetype.a" "${TOOLS}/freetype/libfreetype.a"

# Every C/C++ file sees the Linux-like environment the JDK expects: the
# pthread API maps onto gthread-jspi, a few Linux-only headers are stubbed.
EXTRA_FLAGS="-D__linux__ -D__SIGRTMAX=64 -I${SUPPORT}/compat-include -include gthread_compat.h \
-I${PREFIX}/include/gthread -I${PREFIX}/include"

bash configure \
  --openjdk-target=wasm32-unknown-emscripten \
  --with-jvm-variants=zero --with-toolchain-type=clang \
  --with-debug-level=release \
  --disable-debug-symbols --disable-zip-debug-info \
  --with-boot-jdk="${BOOT_JDK}" \
  --x-includes="${PREFIX}/include" --x-libraries="${PREFIX}/lib" \
  --with-cups-include="${SUPPORT}/cups-stub" \
  --with-fontconfig-include="${PREFIX}/include" \
  --with-freetype-include="${PREFIX}/include/freetype2" --with-freetype-lib="${TOOLS}/freetype" \
  --with-zlib=system --with-giflib=bundled \
  --disable-ccache --disable-precompiled-headers \
  --with-extra-cflags="${EXTRA_FLAGS}" \
  --with-extra-cxxflags="${EXTRA_FLAGS}" \
  --with-extra-ldflags="-L${PREFIX}/lib" \
  --with-milestone=fcs --with-update-version="${JDK_UPDATE}" --with-build-number="${JDK_BUILD}" \
  --with-vendor-name=emscripten-forge \
  --with-num-cores="${JOBS}" \
  CC=emjdk-cc CXX=emjdk-c++ AR=emar NM=llvm-nm OBJCOPY=llvm-objcopy STRIP=/bin/true \
  BUILD_CC=gcc BUILD_CXX=g++ BUILD_LD=gcc \
  LIBFFI_CFLAGS="-I${PREFIX}/include" LIBFFI_LIBS="-L${PREFIX}/lib -lffi"

make images JOBS="${JOBS}" LOG=warn

BUILD_DIR="${SRC_DIR}/build/linux-wasm32-normal-zero-release"
OUT="${SRC_DIR}/_wasm"
export SUPPORT JAVA_HOME_BUILD="${BOOT_JDK}"
bash "${SUPPORT}/link-java.sh" "${BUILD_DIR}" "${OUT}"
bash "${SUPPORT}/stage-jre.sh" "${BUILD_DIR}" "${OUT}" "${SRC_DIR}/_jre"
python3 "${SUPPORT}/pack-jre.py" "${SRC_DIR}/_jre" "${OUT}/openjdk8-jre" --gzip

DEST="${PREFIX}/share/openjdk8-wasm"
mkdir -p "${DEST}" "${PREFIX}/bin"
install -m 644 "${OUT}/openjdk8.js" "${OUT}/openjdk8.wasm" "${OUT}/openjdk8-jre.json" "${OUT}/openjdk8-jre.data.gz" \
               "${SUPPORT}/web/openjdk8-web.js" "${DEST}/"

for f in LICENSE ASSEMBLY_EXCEPTION THIRD_PARTY_README; do
  install -m 644 "${SRC_DIR}/${f}" "${DEST}/${f}"
done
