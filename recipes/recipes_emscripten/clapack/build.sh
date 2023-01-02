#!/bin/bash

# The archive's contents have default permission 0750. If we use docker
# to build, then we will not own the contents in the host, which means
# we cannot navigate into the folder. Setting it to 0750 makes it
# easier to debug.
chmod -R o+rx .

# In CLAPACK's Makefiles, some commands are mistakenly (?) hardcoded
# instead of using the right variables
sed -i 's/^	-ranlib /^	$(RANLIB)/' **/Makefile
sed -i 's/^	ar /^	$(ARCH)/' **/Makefile
sed -i 's/^	ld /^	$(LD)/' **/Makefile


export CFLAGS="CFLAGS -DNO_TRUNCATE"

emmake make -j ${CPU_COUNT} blaslib lapacklib

mkdir -p ${PREFIX}/lib
emcc blas_WA.a lapack_WA.a F2CLIBS/libf2c.a -sSIDE_MODULE -o ${PREFIX}/lib/clapack_all.so

mkdir -p ${PREFIX}/include
cp INCLUDE/clapack.h ${PREFIX}/include