#include <iostream>

#include <executorch/extension/module/module.h>
#include <executorch/extension/tensor/tensor.h>
#include <executorch/runtime/executor/program.h>

int main() {
    executorch::extension::Module* module = nullptr;
    executorch::runtime::Program* program = nullptr;

    (void)module;
    (void)program;

    std::cout << "executorch smoke test passed" << std::endl;
    return 0;
}