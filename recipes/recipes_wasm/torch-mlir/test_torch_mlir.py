import torch

from torch_mlir.dialects import torch as torch_dialect
from torch_mlir.fx import export_and_import
from torch_mlir.ir import Context, Module
from torch_mlir.passmanager import PassManager


def test_parse_and_lower_torch():
    with Context() as context:
        torch_dialect.register_dialect(context)
        module = Module.parse(
            """
            func.func @relu(%input: !torch.vtensor<[4],f32>)
                -> !torch.vtensor<[4],f32> {
              %result = torch.aten.relu %input : !torch.vtensor<[4],f32>
                  -> !torch.vtensor<[4],f32>
              return %result : !torch.vtensor<[4],f32>
            }
            """
        )
        PassManager.parse(
            "builtin.module(torch-backend-to-linalg-on-tensors-backend-pipeline)"
        ).run(module.operation)
        assert module.operation.verify()
        assert "torch.aten" not in str(module)
        assert "linalg.generic" in str(module)


def test_pytorch_fx_export_and_lower():
    class Arithmetic(torch.nn.Module):
        def forward(self, left, right):
            return (left + right) * right

    left = torch.arange(8, dtype=torch.float32)
    right = torch.linspace(-2, 2, 8)
    exported = torch.export.export(Arithmetic(), (left, right), strict=False)
    module = export_and_import(exported, output_type="linalg-on-tensors")
    assert module.operation.verify()
    text = str(module)
    assert "torch.aten" not in text
    assert "arith.addf" in text
    assert "arith.mulf" in text
