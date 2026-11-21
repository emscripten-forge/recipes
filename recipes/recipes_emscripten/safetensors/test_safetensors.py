def test_safetensors():
    import numpy
    from safetensors.numpy import save, load

    tensors = {
        "weight": numpy.array([[1.0, 2.0], [3.0, 4.0]], dtype=numpy.float32),
        "bias": numpy.array([0.1, 0.2], dtype=numpy.float32),
    }

    data = save(tensors)
    assert isinstance(data, bytes)

    loaded = load(data)
    assert set(loaded.keys()) == {"weight", "bias"}
    numpy.testing.assert_array_equal(loaded["weight"], tensors["weight"])
    numpy.testing.assert_array_equal(loaded["bias"], tensors["bias"])
