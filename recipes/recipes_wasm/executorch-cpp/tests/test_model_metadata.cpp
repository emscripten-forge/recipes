#include <filesystem>
#include <iostream>
#include <string_view>
#include <string>

#include <executorch/extension/module/module.h>
#include <executorch/runtime/executor/method_meta.h>

namespace {

using namespace std::string_view_literals;

int fail(const std::string& message) {
    std::cerr << message << std::endl;
    return 1;
}

std::string quoted(std::string_view value) {
    return '"' + std::string(value) + '"';
}

} // namespace

int main(int argc, char** argv) {
    if (argc < 2 || argc > 4) {
        return fail(
            "usage: test_model_metadata <path-to-model.pte> [method-name] [model-label]");
    }

    const std::filesystem::path model_path = argv[1];
    const std::string_view method_name = argc >= 3 ? argv[2] : "forward"sv;
    const std::string_view model_label = argc >= 4 ? argv[3] : "model"sv;

    if (!std::filesystem::is_regular_file(model_path)) {
        return fail("unable to open " + std::string(model_label) + " file: " + model_path.string());
    }

    executorch::extension::Module module(
        model_path.string(),
        executorch::extension::Module::LoadMode::MmapUseMlockIgnoreErrors);

    const auto load_error = module.load(executorch::runtime::Program::Verification::Minimal);
    if (load_error != executorch::runtime::Error::Ok) {
        return fail("failed to load " + std::string(model_label) + " program");
    }

    auto method_names = module.method_names();
    if (!method_names.ok()) {
        return fail("failed to enumerate " + std::string(model_label) + " methods");
    }
    if (!method_names->count(std::string(method_name))) {
        return fail(
            std::string(model_label) + " does not expose method " + quoted(method_name));
    }

    auto method_meta = module.method_meta(std::string(method_name));
    if (!method_meta.ok()) {
        return fail(
            "failed to read " + std::string(model_label) + " method metadata for " + quoted(method_name));
    }
    if (method_meta->num_inputs() == 0) {
        return fail(
            std::string(model_label) + " method " + quoted(method_name) + " unexpectedly has zero inputs");
    }
    if (method_meta->num_outputs() == 0) {
        return fail(
            std::string(model_label) + " method " + quoted(method_name) + " unexpectedly has zero outputs");
    }

    std::cout << model_label << " metadata test passed"
              << " (method=" << method_name
              << ", inputs=" << method_meta->num_inputs()
              << ", outputs=" << method_meta->num_outputs() << ")"
              << std::endl;
    return 0;
}