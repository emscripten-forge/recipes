def test_add():
    import mymodule
    assert mymodule.add(2, 3) == 5
    assert mymodule.add(-1, 1) == 0
