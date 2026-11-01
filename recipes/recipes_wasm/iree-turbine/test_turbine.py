import io
import zipfile

import torch
import iree.runtime as rt
from torch.fx.experimental.proxy_tensor import make_fx
from iree.turbine import aot


class TrainingStep(torch.nn.Module):
    def forward(self, weight, bias, inputs, targets):
        def objective(weight, bias):
            predictions = weight * inputs + bias
            return torch.nn.functional.mse_loss(predictions, targets)

        gradients, loss = torch.func.grad_and_value(objective, argnums=(0, 1))(
            weight, bias
        )
        return weight - .1 * gradients[0], bias - .1 * gradients[1], loss


def test_export_training_to_webgpu():
    inputs = torch.arange(-1, 1, .125)
    arguments = (torch.tensor([.5]), torch.tensor([-.25]), inputs, 2 * inputs + 1)
    traced = make_fx(TrainingStep())(*arguments)
    exported = torch.export.export(traced, arguments, strict=False)
    exported = exported.run_decompositions(aot.current_aot_decompositions())
    program = aot.export(exported)
    program.verify()
    program.session.set_flags(
        '--iree-hal-target-device=webgpu',
        '--iree-opt-level=O3',
        '--iree-torch-allow-non-finites=false',
        '--iree-opt-const-eval=false',
    )
    output = program.compile(save_to=None, target_backends=None)
    try:
        binary = bytes(output.map_memory())
    finally:
        output.close()
    with zipfile.ZipFile(io.BytesIO(binary)) as archive:
        shaders = [name for name in archive.namelist()
                   if name.endswith('_webgpu_wgsl_fb.fb')]
        assert shaders
        assert all(b'@compute' in archive.read(name) for name in shaders)
    module = rt.VmModule.copy_buffer(rt.VmInstance(), binary)
    assert 'main' in module.function_names
