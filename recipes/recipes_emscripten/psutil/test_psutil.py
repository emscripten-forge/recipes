
def test_psutil():
    import psutil
    assert psutil.__version__
    assert psutil.cpu_count() >= 1
