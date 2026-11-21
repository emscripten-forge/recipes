import pytest


def test_import_passagemath_flint():
    import passagemath_flint


def test_number_of_partitions():
    import passagemath_flint
    from sage.libs.flint.arith_sage import number_of_partitions
    assert number_of_partitions(100) == 190569292
