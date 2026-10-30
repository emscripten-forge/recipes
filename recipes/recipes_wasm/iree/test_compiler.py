import io
import zipfile

import pytest

from iree.compiler import ir
from iree.compiler.api import Output, Session, Source


@pytest.mark.parametrize(
    "input_type,model",
    [
        (
            "stablehlo",
            """
            func.func @add(%a: tensor<4xf32>, %b: tensor<4xf32>)
                -> tensor<4xf32> {
              %result = stablehlo.add %a, %b : tensor<4xf32>
              return %result : tensor<4xf32>
            }
            """,
        ),
        (
            "torch",
            """
            func.func @relu(%a: !torch.vtensor<[4],f32>)
                -> !torch.vtensor<[4],f32> {
              %result = torch.aten.relu %a : !torch.vtensor<[4],f32>
                  -> !torch.vtensor<[4],f32>
              return %result : !torch.vtensor<[4],f32>
            }
            """,
        ),
    ],
)
def test_compile_webgpu_in_process(input_type, model):
    with Session() as session:
        session.set_flags(
            f"--iree-input-type={input_type}",
            "--iree-hal-target-device=webgpu",
            "--iree-opt-level=O3",
            "--iree-opt-const-eval=false",
        )
        assert isinstance(session.context, ir.Context)
        with (
            session.invocation() as invocation,
            Source.wrap_buffer(session, model.encode()) as source,
        ):
            invocation.enable_console_diagnostics()
            assert invocation.parse_source(source)
            assert invocation.execute()
            with Output.open_membuffer() as output:
                invocation.output_vm_bytecode(output)
                binary = bytes(output.map_memory())
        with zipfile.ZipFile(io.BytesIO(binary)) as archive:
            assert archive.read("module.fb")[8:12] == b"IREE"
            shaders = [n for n in archive.namelist() if n.endswith("_webgpu_wgsl_fb.fb")]
            assert shaders
            for name in shaders:
                shader = archive.read(name)
                assert shader.startswith(b"WGS1")
                assert b"@compute" in shader


def test_invalid_source_is_rejected():
    with Session() as session, session.invocation() as invocation:
        with Source.wrap_buffer(session, b"not valid MLIR") as source:
            assert not invocation.parse_source(source)
