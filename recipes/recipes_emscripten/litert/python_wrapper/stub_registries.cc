// The cmake feature gates (LITERT_ENABLE_GPU/NPU=OFF) exclude the
// accelerator registry sources, but auto_registration.cc references the
// Register* functions unconditionally; provide a matching stub for the GPU
// registry (npu_registry.cc ships its own LITERT_DISABLE_NPU fallback, and
// webnn_registry.cc is always compiled) so the side module's dlopen
// resolution succeeds (the caller ignores the status).
#include "litert/c/litert_common.h"
#include "litert/core/environment.h"

namespace litert::internal {

LiteRtStatus RegisterGpuAccelerator(LiteRtEnvironment environment) {
  return kLiteRtStatusErrorUnsupported;
}

}  // namespace litert::internal