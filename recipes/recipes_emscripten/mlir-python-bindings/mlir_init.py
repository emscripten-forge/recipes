import sys

if sys.platform == "emscripten":
    # Emscripten's dynamic linker resolves SIDE_MODULE dependencies by library
    # name, not by searching package directories. Pre-load the three shared libs
    # with full absolute paths (in dependency order) so they are registered in
    # the runtime before any extension module's dlopen resolves them.
    #
    # Dependency order (from dylink.0 neededDynlibs):
    #   libnanobind-mlir.so       – no deps
    #   libMLIRPythonCAPI.so.22.1 – no deps
    #   libMLIRPythonSupport-mlir.so – needs nanobind + CAPI
    import ctypes
    import os

    _libs_dir = os.path.join(os.path.dirname(__file__), "_mlir_libs")
    for _lib in (
        "libnanobind-mlir.so",
        "libMLIRPythonCAPI.so.22.1",
        "libMLIRPythonSupport-mlir.so",
    ):
        _p = os.path.join(_libs_dir, _lib)
        if os.path.exists(_p):
            ctypes.CDLL(_p, ctypes.RTLD_GLOBAL)
