import numpy as np


def _sine(sr, freq=440.0, seconds=0.5):
    t = np.arange(int(sr * seconds)) / sr
    return np.sin(2 * np.pi * freq * t).astype(np.float32)


def test_version():
    import soxr

    assert soxr.__version__
    assert soxr.__libsoxr_version__


def test_resample_keeps_frequency():
    import soxr

    x = _sine(44100)
    y = soxr.resample(x, 44100, 16000)
    assert y.dtype == np.float32
    assert abs(len(y) - 8000) <= 1
    # the 440 Hz peak survives resampling
    spec = np.abs(np.fft.rfft(y))
    freqs = np.fft.rfftfreq(len(y), 1 / 16000)
    assert abs(freqs[np.argmax(spec)] - 440) < 5


def test_multichannel_and_stream():
    import soxr

    x = np.stack([_sine(48000), _sine(48000, 880)], axis=1).astype(np.float64)
    y = soxr.resample(x, 48000, 24000, quality="HQ")
    assert y.shape[1] == 2 and abs(y.shape[0] - 12000) <= 1

    rs = soxr.ResampleStream(48000, 24000, 1, dtype="float32")
    mono = _sine(48000)
    out = [rs.resample_chunk(mono[i : i + 4800]) for i in range(0, len(mono), 4800)]
    out.append(rs.resample_chunk(np.zeros(0, np.float32), last=True))
    assert abs(sum(len(o) for o in out) - 12000) <= 2
