import pytest


def test_import_passagemath_ecl():
    import passagemath_ecl


def test_ecl_eval():
    import passagemath_ecl
    from sage.libs.ecl import ecl_eval
    ecl_eval('(cons 1 1)')
