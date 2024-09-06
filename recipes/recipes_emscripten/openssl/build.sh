#!/bin/bash

emconfigure ./Configure gcc -no-ui-console -DHAVE_FORK=0 -DOPENSSL_NO_SECURE_MEMORY -DNO_SYSLOG -fPIC -sWASM_BIGINT

# if on a mac
if [[ $(uname) == Darwin ]]; then
    sed -i '' -e 's!^CROSS_COMPILE=.*!!g' Makefile
else
    sed -i -e 's!^CROSS_COMPILE=.*!!g' Makefile
fi


make build_generated
make -j ${CPU_COUNT:-3} libcrypto.a
make -j ${CPU_COUNT:-3} libssl.a
emar -d libcrypto.a liblegacy-lib-bn_asm.o liblegacy-lib-des_enc.o liblegacy-lib-fcrypt_b.o
# mkdir dist


mkdir -p ${PREFIX}/include
mkdir -p ${PREFIX}/lib 

emcc -sSIDE_MODULE=1 libcrypto.a -o ${PREFIX}/lib/libcrypto.so -sWASM_BIGINT
emcc -sSIDE_MODULE=1 libssl.a -o ${PREFIX}/lib/libssl.so -sWASM_BIGINT


cp -r include/crypto  ${PREFIX}/include/crypto
cp -r include/openssl ${PREFIX}/include/openssl

cp  libcrypto.a  ${PREFIX}/lib
cp  libssl.a     ${PREFIX}/lib