import numpy as np
import tinyarray as ta


def test_multidimensional_aligned_dtypes():
    for dtype in (float, complex):
        for shape in ((1, 2), (2, 3), (2, 2, 2)):
            array = ta.ones(shape, dtype)

            assert ta.array(np.asarray(array)) == array
            assert array + array == 2 * array

        matrix = ta.ones((2, 2), dtype)
        assert ta.dot(matrix, matrix) == ta.array([[2, 2], [2, 2]])
