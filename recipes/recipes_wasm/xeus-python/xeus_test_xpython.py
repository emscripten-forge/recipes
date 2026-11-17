import math
import platform
import sys

import pytest


def test_ipython_shell():
    from IPython import get_ipython
    from IPython.display import display

    assert get_ipython() is not None, "get_ipython() returned None"
    display("hello from xeus-python")


def test_platform():
    print(sys.version)
    print(platform.platform())

    assert sys.platform == "emscripten"
    assert platform.system() == "Emscripten"


def test_machine():
    machine = platform.machine()
    assert machine in ("wasm32", "wasm64")

    expected_maxsize = 2**31 - 1 if machine == "wasm32" else 2**63 - 1
    assert sys.maxsize == expected_maxsize


def test_python_version():
    expected_version = ".".join(str(v) for v in sys.version_info[:3])
    assert platform.python_version() == expected_version


def test_math():
    # sqrt(2) = 1.41421356237309504880...
    assert math.sqrt(2) == pytest.approx(1.4142135623730950, abs=1e-12)
    assert math.sqrt(2) ** 2 == pytest.approx(2.0, abs=1e-12)
    assert math.pi == pytest.approx(3.1415926535897932, abs=1e-12)


def test_text_file(tmp_path):
    path = tmp_path / "test.txt"
    text = "Hello from xeus-python\nSecond line with unicode: éèê\n"
    path.write_text(text, encoding="utf-8")

    assert path.exists()
    assert path.read_text(encoding="utf-8") == text
    assert [p.name for p in tmp_path.iterdir()] == ["test.txt"]

    path.unlink()
    assert not path.exists()


def test_binary_file(tmp_path):
    path = tmp_path / "test.bin"
    data = bytes(range(256))
    path.write_bytes(data)

    assert path.read_bytes() == data
    assert path.stat().st_size == len(data)
