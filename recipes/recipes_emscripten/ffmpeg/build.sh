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

export CFLAGS="-I${PREFIX}/include -pthread ${CFLAGS:-}"
export LDFLAGS="-L${PREFIX}/lib -pthread ${LDFLAGS:-}"

# llvm-nm avoids the broken packaged emnm Python launcher.
./configure \
  --prefix="${PREFIX}" \
  --target-os=none --arch=wasm --enable-cross-compile \
  --disable-stripping \
  --disable-doc --disable-debug --disable-runtime-cpudetect \
  --disable-autodetect --enable-pthreads --disable-w32threads \
  --disable-os2threads --disable-ffplay --disable-network \
  --enable-static --disable-shared \
  --enable-gpl --enable-version3 \
  --enable-ffmpeg --enable-ffprobe \
  --nm=llvm-nm --ar=emar --ranlib=emranlib \
  --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc \
  --enable-avcodec --enable-avformat --enable-avutil \
  --enable-swscale --enable-swresample \
  --enable-avfilter --enable-avdevice \
  --enable-protocol=file

make EXESUF=.js -j"${CPU_COUNT:-4}"
make EXESUF=.js install

# FFmpeg's Emscripten link creates *_g.wasm and copies only the JavaScript
# launcher during install. Give each launcher a stable adjacent wasm file.
for tool in ffmpeg ffprobe; do
  if [[ ! -s "${tool}_g.wasm" || ! -s "${PREFIX}/bin/${tool}.js" ]]; then
    echo "error: ${tool} CLI was not built; expected ${tool}_g.wasm and ${PREFIX}/bin/${tool}.js" >&2
    exit 1
  fi
  install -Dm755 "${tool}_g.wasm" "${PREFIX}/bin/${tool}.wasm"
  sed -i "s/${tool}_g\\.wasm/${tool}.wasm/g" "${PREFIX}/bin/${tool}.js"
  if [[ ! -s "${PREFIX}/bin/${tool}.wasm" ]]; then
    echo "error: failed to install ${PREFIX}/bin/${tool}.wasm" >&2
    exit 1
  fi
done

install -Dm644 "${RECIPE_DIR}/cmake/FFmpegConfig.cmake" \
  "${PREFIX}/lib/cmake/FFmpeg/FFmpegConfig.cmake"

# FFmpeg writes its build-time prefix into pkg-config files. Make them
# relocatable after packaging.
sed -i 's|^prefix=.*|prefix=${pcfiledir}/../..|' "${PREFIX}/lib/pkgconfig/"*.pc
find "${PREFIX}" -name '*.la' -delete
