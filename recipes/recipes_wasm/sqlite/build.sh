#!/bin/bash
set -e

# Built from the amalgamation (one sqlite3.c, see recipe.yaml): no configure,
# no tcl / code generators needed, just emcc + emar.
#
# -fvisibility=hidden: the sqlite3_* symbols stay local to whatever links this
# static lib. Otherwise every side module using sqlite (python's _sqlite3,
# apsw, ...) exports the whole sqlite3_* API: the extension loader's table of
# pointers to all API functions (sqlite3Apis) makes them address-taken, and
# in a PIC side module address-taken default-visibility functions go through
# the GOT and are exported. The dynamic linker then binds them to another
# loaded copy of sqlite (e.g. one in the main module), whose state the module
# never initialized ("null function" trap in sqlite3_close).
#
# The options are the ones the configure build had: no threads, column
# metadata, math functions, JSON (default).
SQLITE_FLAGS=(
    -DSQLITE_THREADSAFE=0
    -DSQLITE_ENABLE_COLUMN_METADATA=1
    -DSQLITE_ENABLE_MATH_FUNCTIONS
    -DSQLITE_OMIT_POPEN
    -DHAVE_USLEEP=1
    -DHAVE_LOCALTIME_R=1
    -DHAVE_GMTIME_R=1
    -DHAVE_FDATASYNC=1
    -DHAVE_STRCHRNUL=1
    -DHAVE_MALLOC_USABLE_SIZE=1
)

emcc ${CFLAGS} -O2 -fPIC -fvisibility=hidden "${SQLITE_FLAGS[@]}" -c sqlite3.c -o sqlite3.o
emar rcs libsqlite3.a sqlite3.o

mkdir -p "${PREFIX}/lib/pkgconfig" "${PREFIX}/include"
cp libsqlite3.a "${PREFIX}/lib/"
cp sqlite3.h sqlite3ext.h "${PREFIX}/include/"

cat > "${PREFIX}/lib/pkgconfig/sqlite3.pc" << EOF
prefix=${PREFIX}
exec_prefix=\${prefix}
libdir=\${exec_prefix}/lib
includedir=\${prefix}/include

Name: SQLite
Description: SQL database engine
Version: ${PKG_VERSION}
Libs: -L\${libdir} -lsqlite3
Libs.private:
Cflags: -I\${includedir}
EOF
