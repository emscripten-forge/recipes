def test_numpy():
    import numpy as np

    ones = np.ones(shape=[2,3])
    assert ones.shape == (2,3)
    
        

    # 1. Array creation & dtype
    a = np.arange(6).reshape(2, 3)
    print("Array a:\n", a, "dtype:", a.dtype)

    # 2. Elementwise ops & broadcasting
    b = np.ones((2, 1))
    print("a + b (broadcasted):\n", a + b)

    # 3. Reduction
    print("Sum of a:", np.sum(a))

    # 4. Matrix multiplication (BLAS check)
    c = np.array([[1, 2], [3, 4]])
    d = np.array([[5, 6], [7, 8]])
    print("Matrix product c @ d:\n", c @ d)

    # 5. Linear algebra (LAPACK check)
    eigvals, eigvecs = np.linalg.eig(c)
    print("Eigenvalues of c:", eigvals)

    # 6. Random numbers
    rng = np.random.default_rng(42)
    print("Random sample:", rng.random(3))
