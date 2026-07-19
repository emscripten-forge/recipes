import sys

if sys.platform == "emscripten":
    # Emscripten's dynamic linker resolves neededDynlibs by SHORT NAME, searching
    # directories like /lib/. But ctypes.CDLL with a full path registers the library
    # under that full path as the key — so when libMLIRPythonSupport-mlir.so tries
    # to load libnanobind-mlir.so as a neededDynlib, the short-name lookup fails.
    #
    # Fix: create symlinks in /lib/ so Emscripten finds the libs by short name,
    # then load via those symlink paths (which registers them under /lib/<name>).
    import ctypes
    import os

    _libs_dir = os.path.join(os.path.dirname(__file__), "_mlir_libs")

    # Create /lib/<name> symlinks (no data copy — MEMFS just adds a dir entry)
    for _lib in (
        "libnanobind-mlir.so",
        "libMLIRPythonCAPI.so.22.1",
        "libMLIRPythonSupport-mlir.so",
    ):
        _src = os.path.join(_libs_dir, _lib)
        _dst = f"/lib/{_lib}"
        if os.path.exists(_src) and not os.path.exists(_dst):
            try:
                os.symlink(_src, _dst)
            except OSError:
                pass

    # Load in dependency order via the /lib/ paths so the short-name registry
    # entries are populated before any extension module's dlopen runs.
    for _lib in (
        "libnanobind-mlir.so",
        "libMLIRPythonCAPI.so.22.1",
        "libMLIRPythonSupport-mlir.so",
    ):
        _p = f"/lib/{_lib}"
        if os.path.exists(_p):
            ctypes.CDLL(_p, ctypes.RTLD_GLOBAL)
