REM edited from the one from Anaconda
copy %RECIPE_DIR%\CMakeLists.txt CMakeLists.txt

mkdir build
cd build

cmake -G "Ninja" ^
      -D CMAKE_INSTALL_PREFIX=%LIBRARY_PREFIX% ^
      -D CMAKE_PREFIX_PATH=%LIBRARY_PREFIX% ^
      -D CMAKE_BUILD_TYPE=Release ^
      -D BUILD_SHARED_LIBS=OFF ^
      -D BZIP2_SKIP_TOOLS=ON ^
      ..

ninja install --verbose