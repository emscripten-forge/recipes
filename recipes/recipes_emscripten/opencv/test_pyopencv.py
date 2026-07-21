import cv2
import numpy as np
import pytest


def test_version():
    assert isinstance(cv2.__version__, str)
    assert len(cv2.__version__) > 0


def test_build_configuration_includes_enabled_backends():
    info = cv2.getBuildInformation()

    assert "GDAL" in info
    assert "GDCM" in info
    assert "Protobuf" in info


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
    img[2:8, 2:8] = [255, 0, 0]
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


def test_enabled_module_entry_points_exist():
    kalman = cv2.KalmanFilter(2, 1)
    assert kalman.statePre.shape == (2, 1)

    qr_detector = cv2.QRCodeDetector()
    qr_detector.setEpsX(0.3)
    qr_detector.setEpsY(0.4)
    qr_detector.setUseAlignmentMarkers(True)

    stitcher = cv2.Stitcher.create()
    assert stitcher is not None

    blob = cv2.dnn.blobFromImage(np.ones((2, 2, 3), dtype=np.float32))
    assert blob.ndim == 4


def test_video_capture():
    """Download a short video and try reading it with VideoCapture."""
    import os
    import urllib.request

    url = (
        "https://test-videos.co.uk/vids/bigbuckbunny/mp4/h264/360/"
        "Big_Buck_Bunny_360_10s_5MB.mp4"
    )
    tmp_path = "/tmp/bigbuckbunny.mp4"

    try:
        urllib.request.urlretrieve(url, tmp_path)
    except Exception as exc:
        # Downloading may not work in the pyjs/browser environment
        pytest.skip(f"Download failed ({exc}), skipping video test")

    assert os.path.getsize(tmp_path) > 0, "Downloaded file is empty"

    cap = cv2.VideoCapture(tmp_path)
    assert cap.isOpened(), "Failed to open video file with VideoCapture"

    ret, frame = cap.read()
    assert ret, "Failed to read first frame"
    assert frame is not None, "First frame is None"
    assert frame.size > 0, "First frame has no pixels"

    # Clean up
    cap.release()
    os.remove(tmp_path)
