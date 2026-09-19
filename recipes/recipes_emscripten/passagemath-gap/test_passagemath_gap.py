import pytest


def test_import_passagemath_gap():
    import passagemath_gap


def test_libgap():
    import passagemath_gap
    from sage.libs.gap.libgap import libgap
    libgap(10)
