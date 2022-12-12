mkdir build
cd build

cmake .. ^
    -GNinja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
    -DXWIDGETS_BUILD_SHARED_LIBS=OFF ^
    -DXWIDGETS_BUILD_STATIC_LIBS=ON  ^

if errorlevel 1 exit 1

ninja install --verbose
if errorlevel 1 exit 1
