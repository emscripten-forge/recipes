def test_import_hypothesis():
    import hypothesis


def test_given_integers():
    from hypothesis import given, strategies as st

    seen = []

    @given(st.integers(min_value=0, max_value=10))
    def f(n):
        seen.append(n)
        assert 0 <= n <= 10

    f()
    assert seen
