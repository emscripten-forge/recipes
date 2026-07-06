import cv2
import numpy as np


def test_version():
    assert isinstance(cv2.__version__, str)
    assert len(cv2.__version__) > 0


def test_mat_creation():
    m = np.zeros((3, 3), dtype=np.float32)
    assert m.shape == (3, 3)
    assert m.dtype == np.float32


def test_basic_core_ops():
    left = np.full((4, 4), 10, dtype=np.uint8)
    right = np.full((4, 4), 30, dtype=np.uint8)

    summed = cv2.add(left, right)
    blended = cv2.addWeighted(left, 0.25, right, 0.75, 0.0)
    norm = cv2.norm(right, left, cv2.NORM_L1)

    assert np.all(summed == 40)
    assert np.all(blended == 25)
    assert norm == 320.0


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


def test_resize_and_blur():
    img = np.arange(16, dtype=np.uint8).reshape(4, 4)

    resized = cv2.resize(img, (8, 8), interpolation=cv2.INTER_LINEAR)
    blurred = cv2.GaussianBlur(resized, (3, 3), 0)

    assert resized.shape == (8, 8)
    assert blurred.shape == (8, 8)
    assert blurred.dtype == np.uint8


def test_threshold_and_find_non_zero():
    img = np.zeros((6, 6), dtype=np.uint8)
    img[1:5, 2:4] = 180

    _, binary = cv2.threshold(img, 100, 255, cv2.THRESH_BINARY)
    points = cv2.findNonZero(binary)

    assert binary.sum() == 8 * 255
    assert points is not None
    assert len(points) == 8


def test_photo_denoise_preserves_shape():
    img = np.zeros((12, 12, 3), dtype=np.uint8)
    img[3:9, 3:9] = [40, 120, 200]
    noise = np.full((12, 12, 3), 5, dtype=np.uint8)

    denoised = cv2.fastNlMeansDenoisingColored(cv2.add(img, noise))

    assert denoised.shape == img.shape
    assert denoised.dtype == np.uint8
