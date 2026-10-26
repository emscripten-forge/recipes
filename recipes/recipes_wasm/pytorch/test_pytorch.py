import io

import numpy as np
import pytest
import torch


def test_cpu_configuration_and_numpy():
    assert torch.get_num_threads() == 1
    assert torch.get_num_interop_threads() == 1
    assert not torch.cuda.is_available()
    values = np.arange(12, dtype=np.float32).reshape(3, 4)
    tensor = torch.from_numpy(values)
    tensor[0, 0] = 7
    assert values[0, 0] == 7
    np.testing.assert_allclose((tensor @ tensor.T).numpy(), values @ values.T)
    torch.manual_seed(42)
    first = torch.randn(1025)
    torch.manual_seed(42)
    torch.testing.assert_close(torch.randn(1025), first)


@pytest.mark.parametrize("dtype", [torch.float32, torch.float64, torch.complex64])
def test_blas_and_lapack(dtype):
    matrix = torch.tensor([[4, 2], [2, 3]], dtype=dtype)
    rhs = torch.tensor([1, 2], dtype=dtype)
    torch.testing.assert_close(matrix @ torch.linalg.solve(matrix, rhs), rhs)
    lower = torch.linalg.cholesky(matrix)
    torch.testing.assert_close(lower @ lower.mH, matrix)
    q, r = torch.linalg.qr(matrix)
    torch.testing.assert_close(q @ r, matrix)
    u, s, vh = torch.linalg.svd(matrix)
    torch.testing.assert_close((u * s) @ vh, matrix)
    w, v = torch.linalg.eigh(matrix)
    torch.testing.assert_close((v * w) @ v.mH, matrix)


def test_autograd_training_and_serialization():
    x = torch.linspace(-1, 1, 16)
    y = 2.5 * x - 0.75
    model = torch.nn.Linear(1, 1)
    with torch.no_grad():
        model.weight.zero_()
        model.bias.zero_()
    for _ in range(100):
        model.zero_grad()
        loss = (model(x[:, None]).ravel() - y).square().mean()
        loss.backward()
        with torch.no_grad():
            for parameter in model.parameters():
                parameter.add_(parameter.grad, alpha=-0.1)
    assert loss.item() < 1e-6
    stream = io.BytesIO()
    torch.save(model.state_dict(), stream)
    stream.seek(0)
    restored = torch.load(stream, weights_only=True)
    for name, value in model.state_dict().items():
        torch.testing.assert_close(restored[name], value)


def test_convolution_and_func():
    image = torch.arange(25, dtype=torch.float32).reshape(1, 1, 5, 5)
    weights = torch.ones(1, 1, 3, 3)
    result = torch.relu(torch.nn.functional.conv2d(image, weights) - 60)
    expected = np.array([[0, 3, 12], [39, 48, 57], [84, 93, 102]], dtype=np.float32)
    np.testing.assert_allclose(result.numpy()[0, 0], expected)
    sample = torch.tensor([1., 2., 3.])
    torch.testing.assert_close(
        torch.func.jacrev(lambda value: value.square())(sample),
        torch.diag(2 * sample),
    )


def test_inductor_forward_and_backward():
    from torch._inductor import wasm_compiler

    builds_before = len(wasm_compiler.builds)
    value = torch.arange(8, dtype=torch.float32, requires_grad=True)
    compiled = torch.compile(lambda x: x.square() + 2 * x, fullgraph=True)
    result = compiled(value)
    torch.testing.assert_close(result, value.square() + 2 * value)
    result.sum().backward()
    torch.testing.assert_close(value.grad, 2 * value.detach() + 2)
    assert len(wasm_compiler.builds) > builds_before
