
export CFLAGS="${CFLAGS}    -fwasm-exceptions"
export LDFLAGS="${LDFLAGS}  -fwasm-exceptions"
export CXXFLAGS="${CXXFLAGS}    -fwasm-exceptions"

mkdir -p qhull-build && cd qhull-build
cmake -GNinja $SRC_DIR $CMAKE_ARGS \
     -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
     -DBUILD_SHARED_LIBS=OFF \
     -DBUILD_STATIC_LIBS=ON

ninja install

cp qhull.wasm $PREFIX/bin/qhull.wasm
cp rbox.wasm $PREFIX/bin/rbox.wasm
cp qconvex.wasm $PREFIX/bin/qconvex.wasm
cp qdelaunay.wasm $PREFIX/bin/qdelaunay.wasm
cp qvoronoi.wasm $PREFIX/bin/qvoronoi.wasm
cp qhalf.wasm $PREFIX/bin/qhalf.wasm