mkdir build
cd build

cmake .. ^
    -GNinja ^
    -DCMAKE_BUILD_TYPE=Release ^
    -DCMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
    -DCMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^

if errorlevel 1 exit 1

ninja install --verbose
if errorlevel 1 exit 1
