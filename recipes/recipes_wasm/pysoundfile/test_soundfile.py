import io

import numpy as np


def _sine(sr=16000, freq=440.0, seconds=0.25):
    t = np.arange(int(sr * seconds)) / sr
    return 0.5 * np.sin(2 * np.pi * freq * t)


def test_libsndfile_loaded():
    import soundfile as sf

    assert sf.__libsndfile_version__.startswith("1.2")
    formats = sf.available_formats()
    assert "WAV" in formats and "AIFF" in formats


def test_wav_roundtrip_file(tmp_path):
    import soundfile as sf

    x = np.stack([_sine(), _sine(freq=880)], axis=1)
    path = tmp_path / "tone.wav"
    sf.write(path, x, 16000, subtype="PCM_16")

    info = sf.info(path)
    assert info.samplerate == 16000 and info.channels == 2
    assert info.frames == len(x)

    y, sr = sf.read(path, dtype="float32")
    assert sr == 16000 and y.shape == x.shape
    np.testing.assert_allclose(y, x, atol=1e-3)


def test_inmemory_and_blocks():
    import soundfile as sf

    x = _sine(seconds=1.0).astype(np.float32)
    buf = io.BytesIO()
    sf.write(buf, x, 16000, format="WAV", subtype="FLOAT")
    buf.seek(0)
    blocks = list(sf.blocks(buf, blocksize=4000, dtype="float32"))
    assert len(blocks) == 4
    np.testing.assert_allclose(np.concatenate(blocks), x, atol=1e-3)
