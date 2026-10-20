#!/usr/bin/env bash

set -euo pipefail

# The compiler activation script may contain the literal placeholder
# "$BUILD_PREFIX". Emscripten wrappers use these variables to launch
# emcc/emar, so replace it with the actual build environment path.
export EMSDK_PYTHON="${BUILD_PREFIX}/bin/python3"
export PYTHON="${BUILD_PREFIX}/bin/python3"

# rattler's target-platform variable collides with FFmpeg's internal
# Makefile variable of the same name.
unset SUBDIR

export CFLAGS="-I${PREFIX}/include ${CFLAGS:-}"
export LDFLAGS="-L${PREFIX}/lib ${LDFLAGS:-}"

# llvm-nm avoids the broken packaged emnm Python launcher.
./configure \
  --prefix="${PREFIX}" \
  --target-os=none --arch=x86_32 --enable-cross-compile \
  --disable-asm --disable-stripping --disable-programs \
  --disable-doc --disable-debug --disable-runtime-cpudetect \
  --disable-autodetect --disable-pthreads --disable-w32threads \
  --disable-os2threads --disable-ffplay --disable-network \
  --enable-static --disable-shared \
  --enable-gpl --enable-version3 \
  --nm=llvm-nm --ar=emar --ranlib=emranlib \
  --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc \
  --enable-avcodec --enable-avformat --enable-avutil \
  --enable-swscale --enable-swresample \
  --enable-avfilter --enable-avdevice \
  --enable-protocol=file

make -j"${CPU_COUNT:-4}"
make install

install -Dm644 "${RECIPE_DIR}/cmake/FFmpegConfig.cmake" \
  "${PREFIX}/lib/cmake/FFmpeg/FFmpegConfig.cmake"

# FFmpeg writes its build-time prefix into pkg-config files. Make them
# relocatable after packaging.
sed -i 's|^prefix=.*|prefix=${pcfiledir}/../..|' "${PREFIX}/lib/pkgconfig/"*.pc
find "${PREFIX}" -name '*.la' -delete
