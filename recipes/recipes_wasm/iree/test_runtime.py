import operator
import numpy as np
import iree.runtime as rt
from iree.compiler.api import Output, Session, Source


def test_runtime_api_and_enums():
    assert 'webgpu' in rt.HalDriver.query()
    assert operator.index(rt.MemoryType.DEVICE_LOCAL) == int(rt.MemoryType.DEVICE_LOCAL)
    assert rt.BufferUsage.TRANSFER | rt.BufferUsage.MAPPING == int(
        rt.BufferUsage.TRANSFER
    ) | int(rt.BufferUsage.MAPPING)
    assert rt.HalElementType.map_to_dtype(rt.HalElementType.FLOAT_32) == np.dtype('float32')


def test_load_browser_compiled_module():
    model = b'''func.func @add(%a: tensor<4xf32>, %b: tensor<4xf32>) -> tensor<4xf32> {
      %c = stablehlo.add %a, %b : tensor<4xf32>
      return %c : tensor<4xf32>
    }'''
    with Session() as session:
        session.set_flags('--iree-input-type=stablehlo', '--iree-hal-target-device=webgpu',
                          '--iree-opt-const-eval=false')
        with session.invocation() as invocation, Source.wrap_buffer(session, model) as source:
            invocation.enable_console_diagnostics()
            assert invocation.parse_source(source)
            assert invocation.execute()
            with Output.open_membuffer() as output:
                invocation.output_vm_bytecode(output)
                binary = bytes(output.map_memory())
    instance = rt.VmInstance()
    module = rt.VmModule.copy_buffer(instance, binary)
    assert 'add' in module.function_names
