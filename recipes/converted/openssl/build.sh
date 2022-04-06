#!/bin/bash

emconfigure ./Configure gcc -no-ui-console -DHAVE_FORK=0 -DOPENSSL_NO_SECURE_MEMORY -DNO_SYSLOG -fPIC
sed -i 's!^CROSS_COMPILE=.*!!g' Makefile
make build_generated
make -j ${CPU_COUNT:-3} libcrypto.a
make -j ${CPU_COUNT:-3} libssl.a
emar -d libcrypto.a liblegacy-lib-bn_asm.o liblegacy-lib-des_enc.o liblegacy-lib-fcrypt_b.o
# mkdir dist
emcc -sSIDE_MODULE=1 libcrypto.a -o ${PREFIX}/libcrypto.so
emcc -sSIDE_MODULE=1 libssl.a -o ${PREFIX}/libssl.so

mkdir -p ${PREFIX}/include

cp -r include/crypto  ${PREFIX}/include/crypto
cp -r include/openssl ${PREFIX}/include/openssl

cp -r libcrypto.a  ${PREFIX}/lib
cp -r libssl.a ${PREFIX}/lib