mkdir -p build
cd build

emconfigure ../configure \
    --host=none \
    --disable-parallel4 \
    --disable-dap \
    --disable-dap-remote-tests \
    --disable-nczarr \
    --prefix=$PREFIX

emmake make
emmake make install
