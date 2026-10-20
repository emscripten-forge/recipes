BOOST_SKIP_MODULES="context coroutine fiber mpi python graph_parallel stacktrace cobalt process thread contract log type_erasure"
BOOST_BUILD_MODULES="atomic charconv chrono container date_time exception filesystem graph iostreams json locale math nowide program_options random regex serialization test timer url wave"
WITH_ARGS=""; for m in $BOOST_BUILD_MODULES; do WITH_ARGS="$WITH_ARGS --with-$m"; done

./bootstrap.sh --prefix=${PREFIX}
./b2 headers
./b2 variant=release toolset=emscripten link=static threading=single \
  $WITH_ARGS --disable-icu \
  cxxflags="$SIDE_MODULE_CXXFLAGS \
  -fexceptions \
  -DBOOST_SP_DISABLE_THREADS=1 \
  -DBOOST_WAVE_SUPPORT_THREADING=0" \
  cflags="$SIDE_MODULE_CFLAGS \
  -fexceptions \
  -DBOOST_SP_DISABLE_THREADS=1" \
  linkflags="-fpic $SIDE_MODULE_LDFLAGS" \
  define=BOOST_HAS_PTHREADS=1 \
  --layout=system  \
  --prefix=${PREFIX} \
  install