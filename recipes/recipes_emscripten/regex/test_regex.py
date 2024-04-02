import pytest

@pytest.mark.parametrize("test_input,expected", 
    [
        (("o","foo"), 2),
        (("a","bba"), 3),
        (("a","bbbbba"), 6)
    ]
)
def test_regex(test_input,expected):
    import regex
    assert regex.search(*test_input).end() == expected