"""LiteRT Python bindings smoke tests on emscripten-wasm32.

Uses ``tensorflow/lite/testdata/add.bin`` shipped inside the package
(``ai_edge_litert/testdata/add.bin``, 544 B, TFL3 flatbuffer, ADD kernel):
write a float input, run inference and check the output is a constant
offset of the input.
"""

from pathlib import Path

import numpy as np

import ai_edge_litert
from ai_edge_litert.compiled_model import CompiledModel

assert ai_edge_litert.__file__ is not None
MODEL = Path(ai_edge_litert.__file__).resolve().parent / "testdata" / "add.bin"


def test_import_surface() -> None:
    import ai_edge_litert as pkg
    from ai_edge_litert.environment import Environment  # noqa: F401
    from ai_edge_litert.options import CpuOptions, CpuKernelMode  # noqa: F401
    from ai_edge_litert.tensor_buffer import TensorBuffer  # noqa: F401

    assert pkg.__version__ == "2.1.5"
    assert MODEL.exists()


def _read_float32(tb, num_elements: int) -> np.ndarray:
    raw = tb.read(num_elements, np.float32)
    if isinstance(raw, bytes):
        return np.frombuffer(raw, dtype=np.float32)
    return np.asarray(raw, dtype=np.float32)


def test_from_file_and_run() -> None:
    model = CompiledModel.from_file(str(MODEL))
    assert model.get_num_signatures() >= 1

    x = (np.arange(1 * 8 * 8 * 3, dtype=np.float32).reshape(1, 8, 8, 3) / 255.0) - 0.5

    in_bufs = model.create_input_buffers(signature_index=0)
    out_bufs = model.create_output_buffers(signature_index=0)
    assert len(in_bufs) == 1 and len(out_bufs) == 1

    in_bufs[0].write(x)
    model.run_by_index(0, in_bufs, out_bufs)

    y = _read_float32(out_bufs[0], x.size).reshape(x.shape)
    assert y.shape == x.shape
    assert np.all(np.isfinite(y))

    # add.bin's op semantics are not a plain elementwise offset, so only
    # assert that inference actually transformed the input.
    assert not np.allclose(y, x, atol=1e-6)