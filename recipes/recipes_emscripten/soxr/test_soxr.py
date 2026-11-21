import numpy as np
import pytest


@pytest.mark.parametrize("input_sr, output_sr", [(44100, 22050), (22050, 44100)])
def test_resample(input_sr, output_sr):
    import soxr

    length = 5.0
    frequency = 42

    input_sample_positions = np.arange(0, length, 1 / input_sr)
    output_sample_positions = np.arange(0, length, 1 / output_sr)

    input_signal = np.sin(2 * np.pi * frequency * input_sample_positions)
    predicted_output_signal = np.sin(2 * np.pi * frequency * output_sample_positions)

    output_signal = soxr.resample(input_signal, input_sr, output_sr)

    np.testing.assert_allclose(predicted_output_signal, output_signal, atol=0.0015)
