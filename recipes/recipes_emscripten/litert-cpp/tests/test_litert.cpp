#include <iostream>

#include "litert/c/litert_common.h"
#include "litert/c/litert_webgpu_types.h"
#include "litert/cc/litert_tensor_buffer_types.h"
#include "litert/cc/options/litert_gpu_options.h"

int main() {
    static_assert(sizeof(LiteRtWGPUBuffer) == sizeof(void*));

    if (!litert::IsWebGpuMemory(litert::TensorBufferType::kWebGpuBuffer)) {
        std::cerr << "WebGPU tensor-buffer classification failed" << std::endl;
        return 1;
    }

    if (static_cast<int>(litert::GpuOptions::Backend::kWebGpu) !=
        static_cast<int>(kLiteRtGpuBackendWebGpu)) {
        std::cerr << "WebGPU backend enum mismatch" << std::endl;
        return 1;
    }

    std::cout << "LiteRT WebGPU C++ API surface available" << std::endl;
    return 0;
}