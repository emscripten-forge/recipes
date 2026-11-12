import operator
import struct
import numpy as np
import iree.runtime as rt
from iree.runtime.webgpu import get_webgpu_device
from iree.compiler.api import Output, Session, Source


def test_runtime_api_and_enums():
    assert {'local-sync', 'webgpu'} <= set(rt.HalDriver.query())
    assert callable(get_webgpu_device)
    assert callable(rt.AsyncSession)
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


def test_compile_and_execute_wasm_cpu():
    model = b'''module @cpu_test {
      func.func @add(%a: tensor<4xf32>, %b: tensor<4xf32>) -> tensor<4xf32> {
        %c = stablehlo.add %a, %b : tensor<4xf32>
        return %c : tensor<4xf32>
      }
    }'''
    bits = struct.calcsize('P') * 8
    with Session() as session:
        session.set_flags(
            '--iree-input-type=stablehlo',
            '--iree-hal-target-device=local',
            '--iree-hal-local-target-device-backends=llvm-cpu',
            f'--iree-llvmcpu-target-triple=wasm{bits}-unknown-emscripten',
            '--iree-llvmcpu-target-cpu-features=+simd128',
            '--iree-execution-model=async-internal',
            '--iree-opt-const-eval=false',
        )
        with session.invocation() as invocation, Source.wrap_buffer(session, model) as source:
            invocation.enable_console_diagnostics()
            assert invocation.parse_source(source)
            assert invocation.execute()
            with Output.open_membuffer() as output:
                invocation.output_vm_bytecode(output)
                binary = bytes(output.map_memory())
    config = rt.Config('local-sync')
    context = rt.SystemContext(config=config)
    context.add_vm_module(rt.VmModule.copy_buffer(config.vm_instance, binary))
    left = np.array([-2.0, -0.5, 0.0, 3.0], dtype=np.float32)
    right = np.array([0.25, 2.0, -1.0, -4.0], dtype=np.float32)
    result = context.modules.cpu_test.add(left, right)
    np.testing.assert_array_equal(result.to_host(), left + right)
