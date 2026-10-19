#include "ggml.h"
#include "ggml-backend.h"
#include "ggml-cpu.h"
#include "ggml-webgpu.h"

#include <cmath>
#include <cstdio>
#include <cstring>
#include <vector>

static int g_failures = 0;

static void check(bool cond, const char * what) {
    if (!cond) {
        std::printf("FAIL: %s\n", what);
        ++g_failures;
    }
}

// Build a small f32 add graph, run it on `backend` and compare against the
// reference result. Returns false on any compute or value mismatch.
static bool run_add(ggml_backend_t backend) {
    const int n = 4096;

    struct ggml_init_params params = { /*mem_size*/ 16 * 1024 * 1024, /*mem_buffer*/ nullptr, /*no_alloc*/ true };
    struct ggml_context * ctx = ggml_init(params);
    if (ctx == nullptr) {
        std::printf("FAIL: ggml_init returned null\n");
        ++g_failures;
        return false;
    }

    struct ggml_tensor * a = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, n);
    struct ggml_tensor * b = ggml_new_tensor_1d(ctx, GGML_TYPE_F32, n);
    struct ggml_tensor * c = ggml_add(ctx, a, b);

    struct ggml_cgraph * graph = ggml_new_graph(ctx);
    ggml_build_forward_expand(graph, c);

    ggml_backend_buffer_t buffer = ggml_backend_alloc_ctx_tensors(ctx, backend);
    if (buffer == nullptr) {
        std::printf("FAIL: ggml_backend_alloc_ctx_tensors returned null\n");
        ++g_failures;
        ggml_free(ctx);
        return false;
    }

    std::vector<float> ha(n), hb(n), hc(n, 0.0f);
    for (int i = 0; i < n; ++i) {
        ha[i] = 1.0f + 0.5f * (float) i;
        hb[i] = 2.0f - 0.25f * (float) i;
    }

    ggml_backend_tensor_set(a, ha.data(), 0, (size_t) n * sizeof(float));
    ggml_backend_tensor_set(b, hb.data(), 0, (size_t) n * sizeof(float));

    const enum ggml_status status = ggml_backend_graph_compute(backend, graph);
    ggml_backend_tensor_get(c, hc.data(), 0, (size_t) n * sizeof(float));

    bool ok = status == GGML_STATUS_SUCCESS;
    if (!ok) {
        std::printf("FAIL: ggml_backend_graph_compute returned %d\n", (int) status);
        ++g_failures;
    }
    for (int i = 0; i < n; ++i) {
        if (std::fabs(hc[i] - (ha[i] + hb[i])) > 1e-5f) {
            std::printf("FAIL: element %d is %f, expected %f\n", i, hc[i], ha[i] + hb[i]);
            ++g_failures;
            ok = false;
            break;
        }
    }

    ggml_backend_buffer_free(buffer);
    ggml_free(ctx);
    return ok;
}

int main(void) {
    // The package is built with the CPU and the WebGPU backend linked in, so
    // both must be present in the registry.
    const size_t n_regs = ggml_backend_reg_count();
    std::printf("backend_regs=%zu\n", n_regs);
    check(n_regs >= 2, "expected at least the CPU and WebGPU backend registries");

    ggml_backend_reg_t cpu_reg = ggml_backend_reg_by_name("CPU");
    check(cpu_reg != nullptr, "CPU backend registry is missing");

    ggml_backend_reg_t webgpu_reg = ggml_backend_reg_by_name(GGML_WEBGPU_NAME);
    check(webgpu_reg != nullptr, "WebGPU backend registry is missing");

    // Compiles the wasm SIMD128 quants path, which is what makes the CPU
    // backend usable on wasm.
    const int has_simd = ggml_cpu_has_wasm_simd();
    std::printf("wasm_simd=%d\n", has_simd);
    check(has_simd == 1, "ggml was built without wasm SIMD support");

    ggml_backend_t cpu = ggml_backend_cpu_init();
    check(cpu != nullptr, "ggml_backend_cpu_init failed");
    if (cpu != nullptr) {
        check(run_add(cpu), "CPU backend produced wrong results");
        ggml_backend_free(cpu);
    }

    // WebGPU needs a real adapter with shader-f16. Node does not expose
    // navigator.gpu, so this normally reports the skip; it stays here so a
    // WebGPU-capable JS runtime can still prove the GPU path end to end.
    ggml_backend_dev_t gpu_dev = ggml_backend_dev_by_type(GGML_BACKEND_DEVICE_TYPE_GPU);
    ggml_backend_t gpu = gpu_dev != nullptr ? ggml_backend_dev_init(gpu_dev, nullptr) : nullptr;
    if (gpu != nullptr) {
        std::printf("webgpu_device=%s\n", ggml_backend_dev_name(gpu_dev));
        check(run_add(gpu), "WebGPU backend produced wrong results");
        ggml_backend_free(gpu);
        std::printf("WEBGPU_COMPUTE_OK\n");
    } else {
        std::printf("WEBGPU_COMPUTE_SKIPPED\n");
    }

    std::printf("failures=%d\n", g_failures);
    std::printf("GGML_WASM_TEST_DONE\n");
    return g_failures == 0 ? 0 : 1;
}
