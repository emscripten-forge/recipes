def test_import_safetensors():
    import safetensors

    assert isinstance(safetensors.__version__, str)


def test_safetensors_tensorspec_roundtrip():
    import ctypes

    from safetensors import TensorSpec, deserialize, serialize

    buf = (ctypes.c_float * 6)(1.0, 2.0, 3.0, 4.0, 5.0, 6.0)
    tensors = {
        "weight": TensorSpec(
            dtype="float32",
            shape=[2, 3],
            data_ptr=ctypes.addressof(buf),
            data_len=ctypes.sizeof(buf),
        )
    }

    data = serialize(tensors, metadata={"format": "pt"})
    assert isinstance(data, bytes)
    assert len(data) > 0

    loaded = dict(deserialize(data))
    assert set(loaded) == {"weight"}
    spec = loaded["weight"]
    assert spec["dtype"] == "F32"
    assert spec["shape"] == [2, 3]
    assert bytes(spec["data"]) == bytes(buf)
