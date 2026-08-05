
def test_psutil():
    import psutil
    psutil.cpu_percent(interval=1, percpu=True)
