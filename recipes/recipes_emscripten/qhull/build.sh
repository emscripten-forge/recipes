mkdir -p qhull-build && cd qhull-build
cmake -GNinja $SRC_DIR $CMAKE_ARGS
ninja install

cp qhull.wasm $PREFIX/bin/qhull.wasm
cp qhull.wasm $PREFIX/bin/qhull.wasm
cp rbox.wasm $PREFIX/bin/rbox.wasm
cp qconvex.wasm $PREFIX/bin/qconvex.wasm
cp qdelaunay.wasm $PREFIX/bin/qdelaunay.wasm
cp qvoronoi.wasm $PREFIX/bin/qvoronoi.wasm
cp qhalf.wasm $PREFIX/bin/qhalf.wasm