import pytest


def test_import_cffi_example():
    import cffi_example


def test_person():
    from cffi_example.person import Person

    p = Person("Alex", "Smith", 72)
    assert p.get_age() == 72
    assert p.get_full_name() == "Alex Smith"

    p = Person("x" * 100, "y" * 100, 72)
    assert p.get_full_name() == "x" * 100


from cffi_example import fnmatch

@pytest.mark.parametrize(
    "pattern,name,flags,expected",
    [
        ("foo", "bar", 0, False),
        ("f*", "foo", 0, True),
        ("f*bar", "f/bar", 0, True),
        ("f*bar", "f/bar", fnmatch.FNM_PATHNAME, False),
    ],
)
def test_fnmatch( pattern, name, flags, expected):

    
    from cffi_example import fnmatch
    result = fnmatch.fnmatch(pattern, name, flags)

    
    assert result == expected
