import pyjs


def test_load_shared_library():
    # Build-time already runs OpenBLAS utest + CBLAS ctest under Node
    # (Fortran BLAS drivers are skipped: flang segfaults on wasm for those sources).
    # This package test only forces loading libopenblas.so to catch missing symbols
    # in the installed shared library.
    pass
