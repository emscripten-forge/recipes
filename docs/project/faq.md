# FAQ

This section is relatively empty, feel free to contribute by opening a pull request.

## What is the difference between emscripten-forge and pyodide?

Pyodide is a full python distribution for `emscripten-wasm32` running in the browser.
Therefore all packages are either python packages or shared libraries needed by python packages.
Emscripten-forge on the other hand is a conda channel providing packages for the `emscripten-wasm32` platform.
This means there is a great overlap in the provided python packages, but emscripten-forge also  provided non-python packages for the `emscripten-wasm32` platform.
Furthermore pyodide lives in the `pip` ecosystem, while emscripten-forge lives in the `conda/mamamba/rattler` ecosystem.