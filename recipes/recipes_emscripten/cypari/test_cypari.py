"""Fast smoke tests for cypari.

cypari ships a large doctest suite (``python -m cypari.test``); running it in
the browser takes many minutes, so this only checks that the extension loads,
that the PARI stack is initialised and that a handful of representative calls
return the right answers.
"""

import pytest


def test_import_cypari():
    import cypari

    assert cypari.__version__ == '2.5.6'


def test_pari_is_initialised():
    from cypari import pari

    version = list(pari.version())
    assert version[0] == 2


def test_integer_arithmetic():
    from cypari import pari

    assert int(pari('2^100')) == 2 ** 100
    assert int(pari('fibonacci(100)')) == 354224848179261915075
    assert int(pari(1000).eulerphi()) == 400


def test_primes_and_factoring():
    from cypari import pari

    assert pari('1000000007').isprime()
    assert int(pari(17).nextprime()) == 17
    assert str(pari(100).factor()) == '[2, 2; 5, 2]'


def test_modular_and_linear_algebra():
    from cypari import pari

    assert str(pari('Mod(3,7)') ** 5) == 'Mod(5, 7)'
    assert int(pari('[1,2;3,4]').matdet()) == -2


def test_real_and_elliptic():
    from cypari import pari

    assert float(pari(2).log()) == pytest.approx(0.6931471805599453, abs=1e-12)
    curve = pari('ellinit([0,-1,1,0,0])')
    assert [int(a) for a in curve.ellan(10)] == \
        [1, -2, -1, 2, 1, 2, -2, 0, -2, -2]


def test_pari_errors_are_raised():
    from cypari import pari
    from cypari import PariError

    with pytest.raises(PariError):
        pari('1/0')
