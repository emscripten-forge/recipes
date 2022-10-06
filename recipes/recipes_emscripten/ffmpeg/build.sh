printenv > ~/Robots/repos/MasterThesis/emscripten-forge-recipes/recipes/recipes_emscripten/ffmpeg/env.sh

emconfigure ./configure \
    --extra-cflags="-fPIC" \
    --disable-x86asm \
    --disable-inline-asm \
    --disable-doc \
    --disable-stripping \
    --disable-programs \
    --disable-pthreads \
    --nm="$CONDA_EMSDK_DIR/upstream/bin/llvm-nm -g" \
    --ar=emar --cc=emcc --cxx=em++ --objcc=emcc --dep-cc=emcc --ranlib=emranlib \
    --prefix=${PREFIX}
# emmake make -j${CPU_COUNT}
emmake make
emmake make install