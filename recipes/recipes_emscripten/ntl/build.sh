mkdir -p $PREFIX

cd src

# From https://github.com/Singular/Singular-in-browser/blob/main/build.sh

emconfigure ./configure \
    CXX="em++" \
    CXXFLAGS="-O2 -fexceptions -s WASM=1 -s NODERAWFS=1" \
    PREFIX="$PREFIX" \
    GMP_PREFIX="$PREFIX" \
    NTL_GMP_LIP=on \
    NTL_STD_CXX14=on \
    SHARED=off \
    NATIVE=off \
    TUNE=generic \
    NTL_THREADS=off

sed -e 's/^CC=gcc/CC=emcc -s NODERAWFS=1/' \
    -e 's/^WIZARD=on/WIZARD=off/' \
    makefile > makefile.patched
mv makefile.patched makefile

sed -e 's|^\t\./MakeDesc|\tchmod +x ./MakeDesc \&\& node ./MakeDesc|' \
    -e 's|^\t\./gen_gmp_aux|\tchmod +x ./gen_gmp_aux \&\& node ./gen_gmp_aux|' \
    -e 's|^\t\./gen_lip_gmp_aux|\tchmod +x ./gen_lip_gmp_aux \&\& node ./gen_lip_gmp_aux|' \
    -e 's|^\t\./gen_lip_gmp_aux|\tchmod +x ./gen_lip_gmp_aux \&\& node ./gen_lip_gmp_aux|' \
    makefile > makefile.patched
mv makefile.patched makefile

sed -i 's|if ./CheckFeatures|if node ./CheckFeatures|g' MakeCheckFeatures

if [ -f MakeCheckThreads ]; then
    sed -i 's|./CheckThreads|node ./CheckThreads|g' MakeCheckThreads
fi

emmake make -j8

emmake make install

emranlib "$PREFIX/lib/libntl.a"
