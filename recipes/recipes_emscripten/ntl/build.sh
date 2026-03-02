mkdir -p $PREFIX

cd src
./configure DEF_PREFIX="$PREFIX" SHARED=off NTL_GMP_LIP=on NTL_GF2X_LIB=off
make
make install
