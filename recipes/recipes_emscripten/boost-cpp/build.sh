# from pyodide

./bootstrap.sh --prefix=${PREFIX}
./b2 variant=release toolset=emscripten link=static threading=single \
  --with-date_time --with-filesystem \
  --with-system --with-regex --with-chrono --with-random --with-program_options --disable-icu \
  cxxflags="$SIDE_MODULE_CXXFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1" \
  cflags="$SIDE_MODULE_CFLAGS -fexceptions -DBOOST_SP_DISABLE_THREADS=1" \
  linkflags="-fpic $SIDE_MODULE_LDFLAGS" \
  --layout=system -j"${PYODIDE_JOBS:-3}" --prefix=${PREFIX} \
  install
