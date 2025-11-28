#!/bin/bash

autoreconf -vfi

export LDFLAGS="${LDFLAGS} -L${PREFIX}/lib"
export CFLAGS="${CFLAGS} -I${PREFIX}/include"

export UDUNITS2_XML_PATH=$PREFIX/share/udunits/udunits2.xml
sed -i s@INSERT_UDUNITS_XML_PATH_HERE@${UDUNITS2_XML_PATH}@g lib/xml.c

cat lib/xml.c

emconfigure ./configure --prefix=${PREFIX}  \
            --enable-static     \
            --disable-shared

make -j${CPU_COUNT} ${VERBOSE_AT}
make install
