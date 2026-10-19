import ml_dtypes
import numpy as np


def test_dtype_registration_and_arithmetic():
    for scalar in (
        ml_dtypes.bfloat16,
        ml_dtypes.float8_e4m3fn,
        ml_dtypes.float8_e5m2,
        ml_dtypes.float4_e2m1fn,
        ml_dtypes.int4,
        ml_dtypes.uint4,
    ):
        assert np.dtype(scalar.__name__) == np.dtype(scalar)
        values = np.array([0, 1, 2], dtype=scalar)
        np.testing.assert_array_equal(values.astype(np.float32), [0, 1, 2])
        np.testing.assert_array_equal(
            np.add(values, values).astype(np.float32), [0, 2, 4]
        )


def test_bfloat16_strided_array_and_limits():
    values = np.arange(6, dtype=np.float32).reshape(2, 3)
    reversed_values = values.astype(ml_dtypes.bfloat16)[:, ::-1]
    result = reversed_values + np.array(1, dtype=ml_dtypes.bfloat16)
    np.testing.assert_array_equal(result.astype(np.float32), values[:, ::-1] + 1)
    assert ml_dtypes.finfo(ml_dtypes.bfloat16).bits == 16
    assert ml_dtypes.iinfo(ml_dtypes.int4).min == -8
    assert ml_dtypes.iinfo(ml_dtypes.uint4).max == 15
