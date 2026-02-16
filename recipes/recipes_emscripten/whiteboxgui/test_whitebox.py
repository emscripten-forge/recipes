import pytest


def test_whitebox():
    # This is how it's supposed to behave for now on emscripten platform
    try:
        import whiteboxgui
    except Exception:
        pass
