cmake ./compile -DUSE_OPENMP=OFF

make -j${CPU_COUNT}

${PYTHON} -m pip  install . -vv --install-option=--nomp
