import cv2
import numpy as np


def test_version():
    assert isinstance(cv2.__version__, str)
    assert len(cv2.__version__) > 0


def test_mat_creation():
    m = np.zeros((3, 3), dtype=np.float32)
    assert m.shape == (3, 3)
    assert m.dtype == np.float32


def test_imencode_imdecode():
    img = np.zeros((10, 10, 3), dtype=np.uint8)
    img[2:8, 2:8] = [255, 0, 0]  # Blue square
    ok, buf = cv2.imencode(".png", img)
    assert ok, "imencode failed"
    assert len(buf) > 0

    decoded = cv2.imdecode(buf, cv2.IMREAD_COLOR)
    assert decoded is not None, "imdecode returned None"
    assert decoded.shape == (10, 10, 3)


def test_cvtColor():
    img = np.zeros((5, 5, 3), dtype=np.uint8)
    img[:, :] = [100, 150, 200]
    gray = cv2.cvtColor(img, cv2.COLOR_BGR2GRAY)
    assert gray.shape == (5, 5)
    assert gray.dtype == np.uint8
