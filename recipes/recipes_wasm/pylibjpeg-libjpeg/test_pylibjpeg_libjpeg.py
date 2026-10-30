import io

import numpy as np


def test_import():
    import libjpeg  # noqa: F401


def test_decode_pillow_jpeg():
    from libjpeg import decode, get_parameters
    from PIL import Image

    # a smooth gradient, so lossy JPEG stays close to the original
    x = np.linspace(0, 255, 64)
    arr = np.add.outer(x, x / 4).clip(0, 255).astype(np.uint8)
    buf = io.BytesIO()
    Image.fromarray(arr, mode="L").save(buf, format="JPEG", quality=95)
    data = buf.getvalue()

    params = get_parameters(data)
    assert params["rows"] == 64
    assert params["columns"] == 64

    decoded = decode(data)
    assert decoded.shape == (64, 64)
    expected = np.asarray(Image.open(io.BytesIO(data)))
    assert np.abs(decoded.astype(int) - expected.astype(int)).max() <= 2
