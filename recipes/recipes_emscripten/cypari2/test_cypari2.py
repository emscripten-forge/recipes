def test_cypari2():
    from cypari2 import Pari

    pari = Pari()
    # Arbitrary-precision integers, which is GMP underneath.
    assert str(pari('2^64')) == '18446744073709551616'
    assert str(pari(10**20).nextprime()) == '100000000000000000039'


def test_cypari2_number_fields():
    from cypari2 import Pari

    pari = Pari()
    # The kind of thing SnapPy actually uses PARI for: number fields and
    # integer relations.
    assert str(pari('nfdisc(x^3-2)')) == '-108'
    assert str(pari('lindep([1, 2^0.5, 2^0.5+1])')) == '[-1, -1, 1]~'


def test_cypari2_names_snappy_needs():
    # snappy/pari.py imports exactly these.
    from cypari2 import Pari, Gen, PariError
    from cypari2.pari_instance import (prec_words_to_dec,
                                       prec_words_to_bits,
                                       prec_bits_to_dec,
                                       prec_dec_to_bits)

    assert isinstance(Pari()('2^64'), Gen)
    assert prec_bits_to_dec(64) > 0
