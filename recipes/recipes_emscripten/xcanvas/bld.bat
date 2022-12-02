mkdir build
cd build

cmake .. ^
    -GNinja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DXCANVAS_BUILD_SHARED_LIBS=OFF ^
    -DXCANVAS_BUILD_STATIC_LIBS=ON  ^

if errorlevel 1 exit 1

ninja install --verbose
if errorlevel 1 exit 1
