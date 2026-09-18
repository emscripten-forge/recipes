def test_cypari():
    from cypari import pari

    # Arbitrary-precision integers, which is GMP underneath.
    assert str(pari('2^64')) == '18446744073709551616'
    assert str(pari(10**20).nextprime()) == '100000000000000000039'


def test_cypari_number_fields():
    from cypari import pari

    # The kind of thing SnapPy actually uses PARI for: number fields and
    # integer relations.
    assert str(pari('nfdisc(x^3-2)')) == '-108'
    assert str(pari('lindep([1, 2^0.5, 2^0.5+1])')) == '[-1, -1, 1]~'
