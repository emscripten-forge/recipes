import torch


def test_serial_autograd_with_registered_device():
    from torch.utils.backend_registration import _setup_privateuseone_for_python_backend

    # Register before the first backward in this isolated test environment.
    _setup_privateuseone_for_python_backend()
    with torch.autograd.set_multithreading_enabled(False):
        for _ in range(2):
            value = torch.arange(8, dtype=torch.float32, requires_grad=True)
            value.square().sum().backward()
            torch.testing.assert_close(value.grad, 2 * value.detach())
