import os
from importlib.metadata import version

import pytest

import psutil


def test_version():
    assert version("psutil") == psutil.__version__
    assert psutil.version_info >= (5, 8, 0)


def test_cpu():
    assert psutil.cpu_count() == 1
    assert psutil.cpu_count(logical=False) == 1
    assert psutil.cpu_percent() == 0.0
    assert psutil.cpu_percent(percpu=True) == [0.0]
    assert len(psutil.cpu_times(percpu=True)) == 1
    assert psutil.cpu_times().user >= 0


def test_virtual_memory():
    mem = psutil.virtual_memory()
    print(mem)
    assert mem.total >= 1024**3
    assert 0 < mem.used <= mem.total
    assert mem.available == mem.total - mem.used
    assert 0 < mem.percent < 100
    # (python's own objects make the heap grow)
    blob = bytearray(64 * 1024**2)
    assert psutil.virtual_memory().used >= 64 * 1024**2
    del blob


def test_process():
    p = psutil.Process()
    assert p.pid == os.getpid()
    assert p == psutil.Process(os.getpid())
    assert p.is_running()
    assert p.num_threads() == 1
    assert p.children() == []
    assert p.cpu_affinity() == [0]
    p.cpu_affinity([0])  # (a no-op)
    assert p.memory_info().rss > 0
    assert set(p.as_dict(["pid", "name"])) == {"pid", "name"}
    with p.oneshot():
        assert p.name() == "python"
    with pytest.raises(psutil.NoSuchProcess):
        psutil.Process(os.getpid() + 1)
    with pytest.raises(psutil.AccessDenied):
        p.kill()


def test_process_list():
    assert psutil.pids() == [os.getpid()]
    assert psutil.pid_exists(os.getpid())
    assert [p.info["pid"] for p in psutil.process_iter(["pid"])] == [os.getpid()]


def test_system():
    assert psutil.boot_time() == 0.0
    assert psutil.disk_usage("/").total >= 0
    assert psutil.disk_partitions() == []
    assert psutil.net_io_counters().bytes_sent == 0
    assert psutil.sensors_battery() is None
    assert psutil.swap_memory().total == 0


def test_unknown_raises_access_denied():
    with pytest.raises(psutil.AccessDenied):
        psutil.win_service_iter()
    with pytest.raises(psutil.AccessDenied):
        psutil.Process().rlimit(0)
    with pytest.raises(AttributeError):
        psutil.__not_there__
