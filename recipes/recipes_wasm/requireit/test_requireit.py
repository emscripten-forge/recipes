import pytest


def test_requireit():
    from requireit import ValidationError, require_between, require_positive

    assert require_positive(3) == 3
    assert require_between(0.5, 0.0, 1.0) == 0.5
    with pytest.raises(ValidationError):
        require_positive(-1)
