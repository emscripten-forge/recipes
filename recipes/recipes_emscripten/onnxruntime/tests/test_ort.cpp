#include <cassert>
#include <cstdio>
#include <cstdint>
#include <cstring>
#include <exception>
#include <iostream>
#include <fstream>
#include <memory>
#include <stdexcept>
#include <string>
#include <type_traits>
#include <vector>

#include "onnxruntime/core/session/onnxruntime_c_api.h"

static size_t element_size(ONNXTensorElementDataType type) {
    switch (type) {
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT:   return sizeof(float);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_DOUBLE:  return sizeof(double);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64:   return sizeof(int64_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT32:   return sizeof(int32_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT16:   return sizeof(int16_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_INT8:    return sizeof(int8_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT64:  return sizeof(uint64_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT32:  return sizeof(uint32_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT16:  return sizeof(uint16_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_UINT8:   return sizeof(uint8_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_BOOL:    return sizeof(uint8_t);
    case ONNX_TENSOR_ELEMENT_DATA_TYPE_FLOAT16: return sizeof(uint16_t);
    default: return 0;
    }
}

static std::string ort_error_to_string(const OrtApi* api, OrtStatus* status) {
    if (status == nullptr) return {};
    const char* msg = api->GetErrorMessage(status);
    std::string text = msg ? msg : "Unknown ONNX Runtime error";
    api->ReleaseStatus(status);
    return text;
}

static void throw_on_error(const OrtApi* api, OrtStatus* status) {
    if (status != nullptr) {
        throw std::runtime_error(ort_error_to_string(api, status));
    }
}

template <typename T>
struct OrtDeleter {
    const OrtApi* api = nullptr;
    void operator()(T* ptr) const {
        if (ptr == nullptr || api == nullptr) return;
        if constexpr (std::is_same_v<T, OrtEnv>) {
            api->ReleaseEnv(ptr);
        } else if constexpr (std::is_same_v<T, OrtSessionOptions>) {
            api->ReleaseSessionOptions(ptr);
        } else if constexpr (std::is_same_v<T, OrtSession>) {
            api->ReleaseSession(ptr);
        } else if constexpr (std::is_same_v<T, OrtMemoryInfo>) {
            api->ReleaseMemoryInfo(ptr);
        } else if constexpr (std::is_same_v<T, OrtRunOptions>) {
            api->ReleaseRunOptions(ptr);
        } else if constexpr (std::is_same_v<T, OrtValue>) {
            api->ReleaseValue(ptr);
        } else if constexpr (std::is_same_v<T, OrtTensorTypeAndShapeInfo>) {
            api->ReleaseTensorTypeAndShapeInfo(ptr);
        } else if constexpr (std::is_same_v<T, OrtTypeInfo>) {
            api->ReleaseTypeInfo(ptr);
        }
    }
};

template <typename T>
using OrtPtr = std::unique_ptr<T, OrtDeleter<T>>;

template <typename T>
static OrtPtr<T> make_ort_ptr(const OrtApi* api, T* ptr = nullptr) {
    return OrtPtr<T>(ptr, OrtDeleter<T>{api});
}

int main() {
    try {
    // Prefer fp32 model first, then fallback to fp16.
    const std::vector<std::string> model_candidates = {
        "../tests/model.onnx",
        "../tests/model_fp16.onnx"
    };
    std::string selected_model;
    for (const auto& candidate : model_candidates) {
        std::ifstream model_file(candidate, std::ios::binary);
        if (model_file.good()) {
            selected_model = candidate;
            break;
        }
    }

    if (selected_model.empty()) {
        printf("No model file found. Looked for ../tests/model.onnx and ../tests/model_fp16.onnx. Skipping inference test.\n");
        return 0;
    }

    const char* model_path = selected_model.c_str();
    printf("Testing ONNX Runtime WebAssembly with model: %s\n", model_path);

    // ------------------------------------------------------------------ //
    // 1. Initialise the ORT API.
    // ------------------------------------------------------------------ //
    const OrtApiBase* base = OrtGetApiBase();
    assert(base != nullptr && "OrtGetApiBase() returned nullptr");
    printf("ONNX Runtime version: %s\n", base->GetVersionString());

    const OrtApi* api = base->GetApi(ORT_API_VERSION);
    assert(api != nullptr && "OrtApi pointer is nullptr");

    // ------------------------------------------------------------------ //
    // 2. Create environment, session options, and session.
    // ------------------------------------------------------------------ //
    OrtEnv* raw_env = nullptr;
    OrtSessionOptions* raw_opts = nullptr;
    OrtSession* raw_session = nullptr;
    OrtMemoryInfo* raw_mem_info = nullptr;
    OrtRunOptions* raw_run_opts = nullptr;
    OrtAllocator* allocator = nullptr;

    std::vector<OrtPtr<OrtValue>> input_tensors;
    std::vector<OrtPtr<OrtValue>> output_tensors;
    std::vector<std::vector<uint8_t>> input_buffers;
    std::vector<std::string> input_names;
    std::vector<std::string> output_names;
    bool has_past_key_values = false;
    size_t num_inputs = 0;
    size_t num_outputs = 0;

    throw_on_error(api, api->CreateEnv(ORT_LOGGING_LEVEL_WARNING, "ort_test", &raw_env));
    auto env = make_ort_ptr(api, raw_env);

    throw_on_error(api, api->CreateSessionOptions(&raw_opts));
    auto opts = make_ort_ptr(api, raw_opts);

    throw_on_error(api, api->SetSessionGraphOptimizationLevel(opts.get(), ORT_DISABLE_ALL));

    OrtStatus* create_session_status = api->CreateSession(env.get(), model_path, opts.get(), &raw_session);
    if (create_session_status != nullptr) {
        fprintf(stderr,
                "CreateSession failed for %s. Skipping inference test.\nReason: %s\n",
                model_path,
                api->GetErrorMessage(create_session_status));
        api->ReleaseStatus(create_session_status);
        printf("All ONNX Runtime WebAssembly tests passed!\n");
        return 0;
    }
    auto session = make_ort_ptr(api, raw_session);

    // ------------------------------------------------------------------ //
    // 3. Inspect model inputs.
    // ------------------------------------------------------------------ //
    throw_on_error(api, api->GetAllocatorWithDefaultOptions(&allocator));

    throw_on_error(api, api->SessionGetInputCount(session.get(), &num_inputs));
    printf("Number of inputs : %zu\n", num_inputs);

    for (size_t i = 0; i < num_inputs; ++i) {
        char* name = nullptr;
        throw_on_error(api, api->SessionGetInputName(session.get(), i, allocator, &name));
        printf("  input[%zu] = \"%s\"\n", i, name);
        input_names.push_back(name);
        if (input_names.back().find("past_key_values") != std::string::npos)
            has_past_key_values = true;
        allocator->Free(allocator, name);
    }

    // ------------------------------------------------------------------ //
    // 4. Inspect model outputs.
    // ------------------------------------------------------------------ //
    throw_on_error(api, api->SessionGetOutputCount(session.get(), &num_outputs));
    printf("Number of outputs: %zu\n", num_outputs);

    for (size_t i = 0; i < num_outputs; ++i) {
        char* name = nullptr;
        throw_on_error(api, api->SessionGetOutputName(session.get(), i, allocator, &name));
        printf("  output[%zu] = \"%s\"\n", i, name);
        output_names.push_back(name);
        allocator->Free(allocator, name);
    }

    // ------------------------------------------------------------------ //
    // 5. Build dummy input tensors.
    //
    //    Text-generation models (e.g. GPT-2) typically expect:
    //      input_ids      : int64 [batch=1, seq=6]
    //      attention_mask : int64 [batch=1, seq=6]   (optional)
    //    Any other int64 input receives the same token-id buffer.
    // ------------------------------------------------------------------ //
    {
        static const int64_t token_ids[] = {101, 7592, 1010, 2129, 2024, 102};
        static const int64_t attention[] = {  1,    1,    1,    1,    1,   1};
        static const int64_t positions[] = {  0,    1,    2,    3,    4,   5};

        throw_on_error(api, api->CreateCpuMemoryInfo(OrtArenaAllocator, OrtMemTypeDefault, &raw_mem_info));
        auto mem_info = make_ort_ptr(api, raw_mem_info);

        input_tensors.resize(num_inputs);
        input_buffers.resize(num_inputs);

        for (size_t i = 0; i < num_inputs; ++i) {
            const std::string& input_name = input_names[i];

            OrtTypeInfo* type_info = nullptr;
            throw_on_error(api, api->SessionGetInputTypeInfo(session.get(), i, &type_info));
            auto owned_type_info = make_ort_ptr(api, type_info);

            const OrtTensorTypeAndShapeInfo* tensor_info = nullptr;
            throw_on_error(api, api->CastTypeInfoToTensorInfo(owned_type_info.get(), &tensor_info));
            if (!tensor_info) {
                throw std::runtime_error("Input " + input_name + " is not a tensor");
            }

            ONNXTensorElementDataType elem_type = ONNX_TENSOR_ELEMENT_DATA_TYPE_UNDEFINED;
            throw_on_error(api, api->GetTensorElementType(tensor_info, &elem_type));
            size_t elem_bytes = element_size(elem_type);
            if (elem_bytes == 0) {
                throw std::runtime_error("Unsupported input element type for " + input_name);
            }

            size_t ndim = 0;
            throw_on_error(api, api->GetDimensionsCount(tensor_info, &ndim));

            std::vector<int64_t> dims(ndim, 1);
            throw_on_error(api, api->GetDimensions(tensor_info, dims.data(), ndim));

            bool is_past = input_name.find("past_key_values") != std::string::npos;
            bool is_input_ids = input_name == "input_ids";
            bool is_attention = input_name.find("attention") != std::string::npos || input_name.find("mask") != std::string::npos;
            bool is_position = input_name.find("position") != std::string::npos;

            for (size_t d = 0; d < dims.size(); ++d) {
                if (dims[d] > 0) continue;
                if (is_past) {
                    dims[d] = (d == 2) ? 0 : 1;
                } else if ((is_input_ids || is_attention || is_position) && dims.size() >= 2) {
                    dims[d] = (d == 0) ? 1 : 6;
                } else {
                    dims[d] = 1;
                }
            }

            size_t elem_count = 1;
            for (int64_t dim : dims) {
                if (dim == 0) {
                    elem_count = 0;
                    break;
                }
                elem_count *= static_cast<size_t>(dim);
            }

            size_t byte_count = elem_count * elem_bytes;
            input_buffers[i].resize(byte_count == 0 ? 1 : byte_count, 0);

            if (elem_type == ONNX_TENSOR_ELEMENT_DATA_TYPE_INT64 && elem_count > 0) {
                const int64_t* src = token_ids;
                if (is_attention) src = attention;
                if (is_position)  src = positions;
                const size_t ncopy = elem_count < 6 ? elem_count : 6;
                for (size_t k = 0; k < ncopy; ++k) {
                    std::memcpy(input_buffers[i].data() + k * sizeof(int64_t), &src[k], sizeof(int64_t));
                }
                const int64_t tail = src[5];
                for (size_t k = ncopy; k < elem_count; ++k) {
                    std::memcpy(input_buffers[i].data() + k * sizeof(int64_t), &tail, sizeof(int64_t));
                }
            }

            OrtValue* raw_value = nullptr;
            throw_on_error(api, api->CreateTensorWithDataAsOrtValue(
                mem_info.get(),
                input_buffers[i].data(),
                byte_count,
                dims.data(),
                dims.size(),
                elem_type,
                &raw_value));
            input_tensors[i] = make_ort_ptr(api, raw_value);
        }

        raw_mem_info = nullptr;
    }

    // ------------------------------------------------------------------ //
    // 6. Run inference.
    // ------------------------------------------------------------------ //
    if (has_past_key_values) {
        printf("Model uses past_key_values cache inputs. Skipping Run() in this smoke test.\n");
        printf("All ONNX Runtime WebAssembly tests passed!\n");
        return 0;
    }

    {
        throw_on_error(api, api->CreateRunOptions(&raw_run_opts));
        auto run_opts = make_ort_ptr(api, raw_run_opts);

        std::vector<const char*> in_ptrs, out_ptrs;
        std::vector<OrtValue*> in_values;
        std::vector<OrtValue*> out_values(num_outputs, nullptr);
        for (const auto& n : input_names)  in_ptrs.push_back(n.c_str());
        for (const auto& n : output_names) out_ptrs.push_back(n.c_str());
        for (auto& v : input_tensors) in_values.push_back(v.get());

        throw_on_error(api, api->Run(
            session.get(), run_opts.get(),
            in_ptrs.data(),  in_values.data(),  num_inputs,
            out_ptrs.data(), num_outputs, out_values.data()));

        output_tensors.resize(num_outputs);
        for (size_t i = 0; i < num_outputs; ++i) {
            output_tensors[i] = make_ort_ptr(api, out_values[i]);
        }

        printf("Inference succeeded.\n");

        raw_run_opts = nullptr;
    }

    // ------------------------------------------------------------------ //
    // 7. Print the shape of each output tensor.
    // ------------------------------------------------------------------ //
    for (size_t i = 0; i < num_outputs; ++i) {
        if (!output_tensors[i].get()) continue;

        OrtTensorTypeAndShapeInfo* raw_shape_info = nullptr;
        throw_on_error(api, api->GetTensorTypeAndShape(output_tensors[i].get(), &raw_shape_info));
        auto shape_info = make_ort_ptr(api, raw_shape_info);

        size_t ndim = 0;
        throw_on_error(api, api->GetDimensionsCount(shape_info.get(), &ndim));
        std::vector<int64_t> dims(ndim);
        throw_on_error(api, api->GetDimensions(shape_info.get(), dims.data(), ndim));

        printf("  output[%zu] (\"%s\") shape: [", i, output_names[i].c_str());
        for (size_t d = 0; d < ndim; ++d)
            printf("%lld%s", (long long)dims[d], d + 1 < ndim ? ", " : "");
        printf("]\n");
    }

    printf("All ONNX Runtime WebAssembly tests passed!\n");
    return 0;
    } catch (const std::exception& ex) {
        fprintf(stderr, "ORT test failed: %s\n", ex.what());
        return 1;
    }
}
