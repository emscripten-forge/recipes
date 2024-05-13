# Related Projects

## Pyodide

[Pyodide](https://pyodide.org/en/stable/index.html) is a Python distribution for the browser and Node.js based on WebAssembly.
Emscripten-forge would not have been possible without the pioneering work of the pyodide team. 
Many aspects of this project are heavily inspired by the pyodide project. This includes the build scripts and many of the patches which have been taken from the pyodide packages.


## pyjs
[pyjs](https://emscripten-forge.github.io/pyjs/) is modern pybind11 + emscripten Embind based Python <-> JavaScript foreign function interface (FFI) for wasm/emscripten compiled Python.
The API is loosly based on the FFI of pyodide.

## pyjs-code-runner
[pyjs-code-runner](https://github.com/emscripten-forge/pyjs-code-runner) is a "driver" to run python code in a wasm environment, almost like running vanilla python code. This is used to run the tests of the emscripten-forge packages.

## JupyterLite
[JupyterLite](https://jupyterlite.readthedocs.io/en/stable/)  is a JupyterLab distribution that runs entirely in the browser built from the ground-up using JupyterLab components and extensions.


## JupyterLite Xeus

[jupyterlite-xeus](https://github.com/jupyterlite/xeus) is a package/jupyterlite extension to use xeus-kernels
and packages from emscripten-forge in a jupyterlite environment.


## rattler-build

[rattler-build](https://github.com/prefix-dev/rattler-build) is used to build the emscripten-forge packages

## pixi

[pixi](https://pixi.sh/latest/)  is a package management tool for developers. It allows the developer to install libraries and applications in a reproducible way. 
Emscripten-forge uses pixi to setup the environment for building the packages.