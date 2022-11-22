def test_py_arrow():
    import pyarrow as pa

    days = pa.array([1, 12, 17, 23, 28], type=pa.int8())
