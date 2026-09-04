import pytest


def test_add():
    import mymodule
    assert mymodule.add(2, 3) == 5
    assert mymodule.add(-1, 1) == 0


def test_raise_value_error():
    import mymodule
    with pytest.raises(ValueError, match="bad input"):
        mymodule.raise_value_error("bad input")
