#!/bin/bash
# gthread-jspi: cooperative POSIX threads for single-threaded Emscripten
# programs, implemented with JSPI stack switching.
set -euxo pipefail

mkdir -p "${PREFIX}/lib" "${PREFIX}/include/gthread" "${PREFIX}/share/gthread-jspi"

emcc -O2 -Wall -I"${RECIPE_DIR}/include" -c "${RECIPE_DIR}/src/gthread.c" -o gthread.o
emar rcs "${PREFIX}/lib/libgthread-jspi.a" gthread.o

cp "${RECIPE_DIR}/include/gthread.h" "${RECIPE_DIR}/include/gthread_compat.h" "${PREFIX}/include/gthread/"
cp "${RECIPE_DIR}/src/gthread_lib.js" "${PREFIX}/share/gthread-jspi/gthread-library.js"

mkdir -p "${PREFIX}/lib/pkgconfig"
cat > "${PREFIX}/lib/pkgconfig/gthread-jspi.pc" <<PC
prefix=${PREFIX}
libdir=\${prefix}/lib
includedir=\${prefix}/include

Name: gthread-jspi
Description: Cooperative POSIX threads on JSPI stack switching
Version: ${PKG_VERSION}
Cflags: -I\${includedir}/gthread
Libs: -L\${libdir} -lgthread-jspi --js-library \${prefix}/share/gthread-jspi/gthread-library.js -sJSPI -sJSPI_EXPORTS=gt_thread_entry
PC
