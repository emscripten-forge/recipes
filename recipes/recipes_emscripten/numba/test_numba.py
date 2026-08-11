import linecache
import os

import numpy as np
import pytest


def require_global_nrt():
    import ctypes

    # pytester also exercises eager-preload modes which load CPython extensions
    # with RTLD_LOCAL before Numba can request RTLD_GLOBAL.
    try:
        getattr(ctypes.CDLL(None), "NRT_adapt_ndarray_from_python")
    except AttributeError:
        pytest.skip("pytester eagerly preloaded Numba's NRT extension locally")


def test_import_numba():
    import numba

    assert numba.__version__


def test_scalar_jit():
    from numba import njit

    @njit
    def scalar_add(a, b):
        return a + b

    assert scalar_add(1.0, 2.5) == 3.5


def test_array_jit_and_specialization_cache():
    from numba import njit

    require_global_nrt()

    @njit
    def vector_add(a, b):
        out = np.empty_like(a)
        for i in range(len(a)):
            out[i] = a[i] + b[i]
        return out

    a = np.array([1.0, 2.0, 3.0], dtype=np.float64)
    b = np.array([4.0, 5.0, 6.0], dtype=np.float64)

    np.testing.assert_array_equal(vector_add(a, b), [5.0, 7.0, 9.0])
    assert len(vector_add.signatures) == 1

    # Second call must reuse the existing specialization.
    np.testing.assert_array_equal(vector_add(a, b), [5.0, 7.0, 9.0])
    assert len(vector_add.signatures) == 1


def test_array_slice_assignment_on_wasm32():
    from numba import njit

    require_global_nrt()

    @njit
    def initialize_first_row(result, initial):
        result[0, :] = initial
        return result

    initial = np.array([2, 1, 0, 2], dtype=np.int32)
    result = initialize_first_row(np.zeros((3, 4), dtype=np.int32), initial)

    np.testing.assert_array_equal(result[0], initial)
    np.testing.assert_array_equal(result[1:], 0)

    with pytest.raises(ValueError, match="cannot assign slice of shape"):
        initialize_first_row(result, initial[:-1])


def test_persistent_wasm_object_cache(tmp_path, monkeypatch):
    import numba
    from numba import njit

    require_global_nrt()
    monkeypatch.setattr(numba.config, "CACHE_DIR", str(tmp_path))

    def cached_vector_add_impl(a, b):
        out = np.empty_like(a)
        for i in range(a.size):
            out[i] = a[i] + b[i]
        return out

    a = np.array([1.0, 2.0, 3.0])
    b = np.array([4.0, 5.0, 6.0])

    first = njit(cache=True)(cached_vector_add_impl)
    np.testing.assert_array_equal(first(a, b), [5.0, 7.0, 9.0])

    # WASM loads Numba helpers as independent side modules.  Every cached
    # dependency must therefore carry reusable WASM object bytes, not only
    # LLVM bitcode that would need to be emitted again after a reload.
    compile_result = next(iter(first.overloads.values()))
    library_state = compile_result.library.serialize_using_object_code()
    assert len(library_state) == 4
    dependencies = library_state[3]
    assert dependencies
    assert all(kind == "object" for _, kind, _ in dependencies)
    assert all(data[0].startswith(b"\x00asm") for _, _, data in dependencies)

    assert list(tmp_path.rglob("*.nbi"))
    assert list(tmp_path.rglob("*.nbc"))

    second = njit(cache=True)(cached_vector_add_impl)
    np.testing.assert_array_equal(second(a, b), [5.0, 7.0, 9.0])
    assert sum(second.stats.cache_hits.values()) == 1


def test_xeus_notebook_cell_persistent_cache(tmp_path, monkeypatch):
    import numba

    monkeypatch.setattr(numba.config, "CACHE_DIR", str(tmp_path))
    source = (
        "from numba import njit\n"
        "@njit(cache=True)\n"
        "def go_fast(value):\n"
        "    return value + 1\n"
    )
    first_filename = "/tmp/xpython_42/3774261467.py"
    second_filename = "/tmp/xpython_99/3774261467.py"
    linecache.cache[first_filename] = (
        len(source),
        None,
        source.splitlines(keepends=True),
        first_filename,
    )

    try:
        namespace = {"__name__": "__main__"}
        exec(compile(source, first_filename, "exec"), namespace)
        go_fast = namespace["go_fast"]

        assert go_fast(41) == 42
        assert list(tmp_path.rglob("*.nbi"))
        assert list(tmp_path.rglob("*.nbc"))

        # A fresh Xeus kernel has a different PID directory, but the cell's
        # content-addressed basename remains stable.  Recreating the function
        # through that second path must load the specialization from disk.
        linecache.cache[second_filename] = (
            len(source),
            None,
            source.splitlines(keepends=True),
            second_filename,
        )
        second_namespace = {"__name__": "__main__"}
        exec(compile(source, second_filename, "exec"), second_namespace)
        second_go_fast = second_namespace["go_fast"]

        assert second_go_fast(41) == 42
        assert sum(second_go_fast.stats.cache_hits.values()) == 1
    finally:
        linecache.cache.pop(first_filename, None)
        linecache.cache.pop(second_filename, None)


def test_wasm_cache_source_stamp_ignores_unstable_mtime(tmp_path):
    from numba.core import caching

    source = tmp_path / "cached_module.py"
    source.write_text("value = 1\n")
    locator = caching.UserProvidedCacheLocator.__new__(
        caching.UserProvidedCacheLocator
    )
    locator._py_file = str(source)

    first_stamp = locator.get_source_stamp()
    stat = source.stat()
    os.utime(source, (stat.st_atime, stat.st_mtime + 60))

    # JupyterLite reconstructs unchanged packaged sources with new mtimes.
    assert locator.get_source_stamp() == first_stamp

    # A real source change must still invalidate the compiled cache.
    source.write_text("value = 2\n")
    assert locator.get_source_stamp() != first_stamp


def test_wasm_simd_autovectorization():
    from numba import njit

    require_global_nrt()

    @njit(fastmath=True)
    def add_one_inplace(values):
        for i in range(values.size):
            values[i] += np.float32(1.0)

    values = np.arange(1024, dtype=np.float32)
    expected = values + np.float32(1.0)
    add_one_inplace(values)

    np.testing.assert_array_equal(values, expected)
    assembly = add_one_inplace.inspect_asm(add_one_inplace.signatures[0])
    assert "f32x4.add" in assembly
    assert '"simd128"' in assembly


def test_parallel_guvectorize_falls_back_to_cpu():
    from numba import guvectorize

    require_global_nrt()

    @guvectorize(
        ["void(float64[:], float64[:])"],
        "(n)->(n)",
        target="parallel",
        cache=True,
    )
    def add_one(values, result):
        for i in range(values.size):
            result[i] = values[i] + 1.0

    np.testing.assert_array_equal(add_one(np.arange(4.0)), np.arange(1.0, 5.0))
