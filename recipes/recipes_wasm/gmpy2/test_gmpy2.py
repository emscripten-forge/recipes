def test_gmpy2():
    import gmpy2
    from gmpy2 import mpc, mpfr, mpq, mpz, sqrt

    assert mpz(99) * 43 == mpz(4257)
    assert mpq(3, 7) / 7 == mpq(3, 49)

    gmpy2.get_context().allow_complex = True
    assert sqrt(mpfr(-2)) == mpc("0.0+1.4142135623730951j")
