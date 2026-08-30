#!/usr/bin/env bash
set -euxo pipefail

cd M2/BUILD/build

sed -i '/CMP0167/d' \
  ../../cmake/check-libraries.cmake

sed -i '/add_subdirectory(memtailor)/d' \
  ../../Macaulay2/e/CMakeLists.txt

sed -i '/add_subdirectory(mathic)/d' \
  ../../Macaulay2/e/CMakeLists.txt

sed -i '/add_subdirectory(mathicgb)/d' \
  ../../Macaulay2/e/CMakeLists.txt

sed -i '/target_compile_options(mathicgb/,/)/d' \
  ../../Macaulay2/e/CMakeLists.txt

sed -i '/export(TARGETS.*mathicgb/,/)/d' \
  ../../Macaulay2/CMakeLists.txt

sed -i \
  "s|PUBLIC memtailor mathic mathicgb|PUBLIC $PREFIX/lib/libmemtailor.a $PREFIX/lib/libmathic.a $PREFIX/lib/libmathicgb.a|g" \
  ../../Macaulay2/e/CMakeLists.txt

sed -i \
  's|mathicgb mathic memtailor||g' \
  ../../Macaulay2/e/CMakeLists.txt

sed -i '/quadmath/d' \
  ../../Macaulay2/d/CMakeLists.txt

cat << 'EOF' >> ../../Macaulay2/d/CMakeLists.txt

if(EMSCRIPTEN)
  add_custom_target(M2-generated-sources
    DEPENDS ${_c_source}
  )
endif()
EOF

sed -i '/find_package(Readline/d' \
  ../../cmake/check-libraries.cmake

sed -i '/find_package(History/d' \
  ../../cmake/check-libraries.cmake

sed -i 's/READLINE HISTORY //g' \
  ../../cmake/check-libraries.cmake

sed -i '/readline\/readline.h/d' \
  ../../Macaulay2/d/M2lib.c

sed -i '/readline\/history.h/d' \
  ../../Macaulay2/d/M2lib.c

sed -i '/Functions dealing with libreadline/,$d' \
  ../../Macaulay2/d/M2lib.c

cat << 'EOF' >> ../../Macaulay2/d/M2lib.c

#include <stdio.h>
#include <string.h>

int system_readHistory(char *filename)
{
    return 0;
}

int system_appendHistory(int n, char *filename)
{
    return 0;
}

void system_addHistory(char *buf)
{
}

char *system_getHistory(const int n)
{
    return NULL;
}

int system_historyLength()
{
    return 0;
}

void system_initReadlineVariables(void)
{
}

int system_readline(
    M2_string buffer,
    int len,
    int offset,
    M2_string prompt)
{
    char *p = M2_tocharstar(prompt);

    printf("%s", p);
    fflush(stdout);

    freemem(p);

    char *buf_ptr = (char *)buffer->array + offset;

    if (fgets(buf_ptr, len, stdin) == NULL)
        return 0;

    return (int)strlen(buf_ptr);
}
EOF

sed -i '/readline\/readline.h/d' \
  ../../Macaulay2/d/version.dd

sed -i \
  's/"readline version" => Ccode(constcharstar,"stringize(RL_VERSION_MAJOR) \\".\\" stringize(RL_VERSION_MINOR)"),/"readline version" => "not present",/g' \
  ../../Macaulay2/d/version.dd

sed -i '/set(NAUTY_INCLUDE_DIR NOTFOUND)/d' \
  ../../cmake/FindNauty.cmake

sed -i '/set(NAUTY_LIBRARIES NOTFOUND)/d' \
  ../../cmake/FindNauty.cmake

sed -i '/_NAUTY_check_version()/d' \
  ../../cmake/FindNauty.cmake

echo \
  "list(APPEND NORMALIZ_LIBRARIES \"$PREFIX/lib/libcocoa.a\")" \
  >> ../../cmake/FindNormaliz.cmake

echo \
  "list(APPEND FACTORY_LIBRARIES \"$PREFIX/lib/libomalloc.a\" \"$PREFIX/lib/libsingular_resources.a\")" \
  >> ../../cmake/FindFactory.cmake

sed -i \
  '/#include "M2\/config.h"/a #include <stdlib.h>' \
  ../../Macaulay2/c/scc.h

sed -i \
  's/GC_MALLOC(n)/calloc(1, n)/g' \
  ../../Macaulay2/c/scc1.c

sed -i \
  's/\/\* GC_MALLOC clears the memory \*\//\/\* calloc clears the memory \*\//g' \
  ../../Macaulay2/c/scc1.c

sed -i \
  's/GC_INIT();/(void)0;/g' \
  ../../Macaulay2/c/scc1.c

sed -i \
  's/GC_MALLOC(bufsize \*= 2)/getmem(bufsize *= 2)/g' \
  ../../Macaulay2/c/readfile.c

sed -i \
  's/GC_FREE(w);/free(w);/g' \
  ../../Macaulay2/c/chk.c

sed -i '/^if(BDWGC_FOUND AND GDBM_FOUND)$/,/^endif()$/c\
if(GDBM_FOUND)\
  target_link_libraries(scc1\
    ${GDBM_LIBRARY} ${CMAKE_DL_LIBS})\
  target_include_directories(scc1 PUBLIC\
    $<BUILD_INTERFACE:${GDBM_INCLUDE_DIR}>)\
endif()' \
  ../../Macaulay2/c/CMakeLists.txt

cat << 'EOF' >> ../../Macaulay2/c/CMakeLists.txt

if(EMSCRIPTEN)
  target_link_options(scc1 PRIVATE
    "-sFORCE_FILESYSTEM=1"
    "-sNODERAWFS=1"
  )
endif()
EOF

sed -i \
  '/if (flags & constructor_F) put(" __attribute__ ((constructor))");/d' \
  ../../Macaulay2/c/cprint.c

sed -i '/#define GC_THREADS 1/d' \
  ../../include/M2/gc-include.h

sed -i '/#define GC_LINUX_THREADS/d' \
  ../../include/M2/gc-include.h

sed -i \
  's/if (gotArg("--no-threads", argv)) {/if (true) {/' \
  ../../Macaulay2/bin/main.cpp

sed -E -i \
  's/pthread_kill\(interpThread,[[:space:]]*SIGINT\);/(void)0;/g' \
  ../../Macaulay2/system/supervisor.cpp

sed -E -i \
  's/pthread_kill\(interpThread,[[:space:]]*SIGALRM\);/(void)0;/g' \
  ../../Macaulay2/system/supervisor.cpp

sed -E -i \
  's/pthread_kill\(interpThread,[[:space:]]*SIGUSR1\);/(void)0;/g' \
  ../../Macaulay2/system/supervisor.cpp

sed -i \
  's/const static unsigned int numCores = std::thread::hardware_concurrency();/const static unsigned int numCores = 1;/' \
  ../../Macaulay2/system/supervisor.cpp

sed -i '/^  void\*\* TS_Get_LocalArray()/,/^  int getAllowableThreads()/c\
  static void* wasmThreadLocalMemory[1024] = {0};\
  static int wasmThreadLocalIdCounter = 1;\
\
  void** TS_Get_LocalArray()\
  {\
    return wasmThreadLocalMemory;\
  }\
\
  void** TS_Get_Local(int refno)\
  {\
    if (refno <= 0 || refno >= 1024)\
      abort();\
\
    return &wasmThreadLocalMemory[refno];\
  }\
\
  void TS_Add_ThreadLocal(int* refno, const char* name)\
  {\
    (void) name;\
\
    if (*refno != 0)\
      return;\
\
    if (wasmThreadLocalIdCounter >= 1024)\
      abort();\
\
    *refno = wasmThreadLocalIdCounter++;\
  }\
\
  int getAllowableThreads()' \
  ../../Macaulay2/system/supervisor.cpp

rm -f "$PREFIX"/lib/libopenblas.so*

sed -i '/find_program(LDD ldd)/,/^endif()$/c\
set(LDD "")' \
  ../../Macaulay2/bin/CMakeLists.txt

cat << 'EOF' >> ../../Macaulay2/bin/CMakeLists.txt

option(
  M2_EMSCRIPTEN_RUNTIME_BUNDLE
  "Build the final M2 runtime for a file_packager MEMFS data bundle"
  OFF
)

if(EMSCRIPTEN)
  target_link_options(M2-binary PRIVATE

    "-sTOTAL_STACK=32mb"
    "-sINITIAL_MEMORY=2gb"
    "-sALLOW_MEMORY_GROWTH=1"
    "-sMAXIMUM_MEMORY=4gb"
    "-sFORCE_FILESYSTEM=1"
    "-sEXIT_RUNTIME=1"
  )

  if(M2_EMSCRIPTEN_RUNTIME_BUNDLE)
    target_link_options(M2-binary PRIVATE
      "-sNODERAWFS=0"
      "-sENVIRONMENT=web,worker"
    )
  else()
    target_link_options(M2-binary PRIVATE
      "-sNODERAWFS=1"
    )
  endif()
endif()
EOF

sed -i '/file(MAKE_DIRECTORY ${M2_DIST_PREFIX}\/${M2_INSTALL_BINDIR})/i\
if(EMSCRIPTEN)\
  string(CONFIGURE "#!/bin/sh\\n${EXPORT_STRING} exec node --max-old-space-size=4096 `dirname \\"$0\\"`/M2@EXE@ \\"$@\\"" M2_CONTENT @ONLY)\
endif()' \
  ../../Macaulay2/bin/CMakeLists.txt

FAKE_BIN="$PWD/fake-bin"

mkdir -p "$FAKE_BIN"

cat > "$FAKE_BIN/normaliz" << 'EOF'
#!/bin/sh
exit 0
EOF

chmod +x "$FAKE_BIN/normaliz"

cat > "$FAKE_BIN/dreadnaut" << 'EOF'
#!/bin/sh
exit 0
EOF

chmod +x "$FAKE_BIN/dreadnaut"

emcmake cmake \
      -S ../.. \
      -B . \
      -DCMAKE_BUILD_TYPE=Release \
      -DCMAKE_PREFIX_PATH="$PREFIX" \
      -DCMAKE_FIND_ROOT_PATH="$PREFIX" \
      -DBLA_VENDOR=OpenBLAS \
      -DBLAS_LIBRARIES="$PREFIX/lib/libopenblas.a" \
      -DLAPACK_LIBRARIES="$PREFIX/lib/libopenblas.a" \
      -DBoost_NO_BOOST_CMAKE=ON \
      -DWITH_OMP=OFF \
      -DCMAKE_EXE_LINKER_FLAGS="-s ALLOW_MEMORY_GROWTH=1 -s TOTAL_STACK=32MB -s INITIAL_MEMORY=2GB -s MAXIMUM_MEMORY=4GB -s FORCE_FILESYSTEM=1" \
      -DM2_EMSCRIPTEN_RUNTIME_BUNDLE=OFF \
      -DWITH_PYTHON=OFF \
      -DCMAKE_DISABLE_FIND_PACKAGE_LATEX=ON \
      -DCHECK_LIBRARY_COMPATIBILITY=OFF \
      -DNAUTY_EXECUTABLE="$FAKE_BIN/dreadnaut" \
      -DNAUTY_INCLUDE_DIR="$PREFIX/include" \
      -DNAUTY_LIBRARIES="$PREFIX/lib/libnauty.a" \
      -DNAUTY_VERSION_OK=ON \
      -DNORMALIZ_EXECUTABLE="$FAKE_BIN/normaliz" \
      -DNORMALIZ_INCLUDE_DIR="$PREFIX/include" \
      -DNORMALIZ_LIBRARIES="$PREFIX/lib/libnormaliz.a" \
      -DBUILD_NATIVE=OFF

emmake make build-libraries

emmake make M2-generated-sources

M2_D_ORDER=(
  arithmetic
  atomic
  M2
  system
  strings
  varstrin
  strings1
  vararray
  ctype
  nets
  varnets
  interrupts
  pthread0
  stdiop0
  gmp
  ballarith
  engine
  xml
  stdio0
  errio
  parse
  expr
  stdio
  stdiop
  err
  gmp1
  tokens
  getline
  lex
  parser
  binding
  basic
  common
  util
  convertr
  struct
  classes
  buckets
  equality
  hashtables
  regex
  debugging
  evaluate
  sets
  mysql
  mysqldummy
  pthread
  actors
  actors2
  actors3
  actors4
  xmlactors
  actors5
  chrono
  profiler
  threads
  python
  interface
  interface2
  monoid
  monomial_ordering
  texmacs
  boostmath
  atomic2
  json
  ffi
  interp
  version
)

PREPARE_FUNCTIONS=()

for module in "${M2_D_ORDER[@]}"; do

    if [[ -f "Macaulay2/d/${module}-tmp.c" ]]; then

        src="Macaulay2/d/${module}-tmp.c"

    elif [[ -f "Macaulay2/d/${module}-tmp.cc" ]]; then

        src="Macaulay2/d/${module}-tmp.cc"

    else

        continue

    fi

    prepare="$(
        grep -E \
          '^void[[:space:]]+[A-Za-z_][A-Za-z0-9_]*__prepare[[:space:]]*\(\)[[:space:]]*\{' \
          "$src" \
        | head -n 1 \
        | sed -E \
          's/^void[[:space:]]+([A-Za-z_][A-Za-z0-9_]*__prepare)[[:space:]]*\(\)[[:space:]]*\{.*/\1/' \
        || true
    )"

    if [[ -z "$prepare" ]]; then

        echo "ERROR: no _prepare routine found in $src" >&2
        exit 1

    fi

    PREPARE_FUNCTIONS+=("$prepare")

done

PREPARE_DECLS="$PWD/M2-prepare-declarations.inc"
PREPARE_CALLS="$PWD/M2-prepare-calls.inc"

: > "$PREPARE_DECLS"
: > "$PREPARE_CALLS"

for prepare in "${PREPARE_FUNCTIONS[@]}"; do

    printf 'extern "C" void %s(void);\n' \
      "$prepare" \
      >> "$PREPARE_DECLS"

    printf '  %s();\n' \
      "$prepare" \
      >> "$PREPARE_CALLS"

done

MAIN_CPP="../../Macaulay2/bin/main.cpp"
MAIN_NEW="$PWD/main.cpp.explicit-prepares"

awk \
  -v declarations="$PREPARE_DECLS" \
  -v calls="$PREPARE_CALLS" \
  '
  function emit_file(path,    line) {
      while ((getline line < path) > 0)
          print line
      close(path)
  }

  {
      print

      if ($0 ~ /^extern "C" void system_cpuTime_init\(\);$/) {
          print ""
          print "void staticThreadLocalInit(void);"
          print ""
          emit_file(declarations)
          print ""
      }

      if ($0 ~ /^[[:space:]]*GC_INIT\(\);[[:space:]]*$/) {
          print ""
          print "  GC_disable();"
          print ""
          print "  staticThreadLocalInit();"
          print ""
          emit_file(calls)
          print ""
      }
  }
  ' \
  "$MAIN_CPP" \
  > "$MAIN_NEW"

mv "$MAIN_NEW" "$MAIN_CPP"

emmake make M2-binary

sed -i \
  's/tty:true,seekable:false/tty:false,seekable:false/g' \
  usr-dist/x86-Emscripten-Emscripten-1/bin/M2-binary.js

emmake make M2-core

emmake make build-programs

mkdir -p "$PWD/usr-dist/common/share/Macaulay2"

while IFS= read -r package_file; do
    package_name="$(basename "$package_file" .m2)"
    cp "$package_file" "$PWD/usr-dist/common/share/Macaulay2/$package_name.m2"
    if [[ -d "../../Macaulay2/packages/$package_name" ]]; then
        mkdir -p "$PWD/usr-dist/common/share/Macaulay2/$package_name"
        cp -a "../../Macaulay2/packages/$package_name/." "$PWD/usr-dist/common/share/Macaulay2/$package_name/"
    fi
done < <(
    find ../../Macaulay2/packages -maxdepth 1 -type f -name '*.m2' -print | LC_ALL=C sort
)

for metadata_file in '=distributed-packages' '=supplanted-packages' CertificationTemplate; do
    if [[ -f "../../Macaulay2/packages/$metadata_file" ]]; then
        cp "../../Macaulay2/packages/$metadata_file" "$PWD/usr-dist/common/share/Macaulay2/$metadata_file"
    fi
done

if [[ -d ../../Macaulay2/packages/supplanted-packages ]]; then
    mkdir -p "$PWD/usr-dist/common/share/Macaulay2/supplanted-packages"
    cp -a ../../Macaulay2/packages/supplanted-packages/. "$PWD/usr-dist/common/share/Macaulay2/supplanted-packages/"
fi

mkdir -p "$PWD/usr-dist/common/bin"
touch "$PWD/usr-dist/common/bin/M2"

mkdir -p "${PREFIX}/bin"

EMSCRIPTEN_DIR="$(dirname "$(readlink -f "$(command -v emcc)")")"
python3 "${EMSCRIPTEN_DIR}/tools/file_packager.py" \
  "${PREFIX}/bin/M2.data" \
  --preload "${PWD}/usr-dist/common@/m2" \
  --js-output="${PREFIX}/bin/M2.data.js"

emcmake cmake \
  -S ../.. \
  -B . \
  -DM2_EMSCRIPTEN_RUNTIME_BUNDLE=ON

rm -f \
  usr-dist/x86-Emscripten-Emscripten-1/bin/M2-binary.js \
  usr-dist/x86-Emscripten-Emscripten-1/bin/M2-binary.wasm

emmake make M2-binary

cp usr-dist/x86-Emscripten-Emscripten-1/bin/M2-binary.js "${PREFIX}/bin/M2-binary.js"
cp usr-dist/x86-Emscripten-Emscripten-1/bin/M2-binary.wasm "${PREFIX}/bin/M2-binary.wasm"
