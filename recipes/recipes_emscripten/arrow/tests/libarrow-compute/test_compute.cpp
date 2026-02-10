#include <iostream>
#include <arrow/api.h>
#include <arrow/compute/api.h>
#include <arrow/compute/registry.h>

int main() {
    std::cout << "Testing Arrow Compute library..." << std::endl;
    
    // Get compute function registry (lightweight check)
    auto registry = arrow::compute::GetFunctionRegistry();
    
    // Check if basic functions exist
    auto sum_func = registry->GetFunction("sum");
    if (!sum_func.ok()) {
        std::cerr << "Failed to get sum function: " << sum_func.status().ToString() << std::endl;
        return 1;
    }
    std::cout << "Found sum function in registry" << std::endl;
    
    auto filter_func = registry->GetFunction("filter");
    if (!filter_func.ok()) {
        std::cerr << "Failed to get filter function: " << filter_func.status().ToString() << std::endl;
        return 1;
    }
    std::cout << "Found filter function in registry" << std::endl;
    
    auto mean_func = registry->GetFunction("mean");
    if (!mean_func.ok()) {
        std::cerr << "Failed to get mean function: " << mean_func.status().ToString() << std::endl;
        return 1;
    }
    std::cout << "Found mean function in registry" << std::endl;
    
    std::cout << "All Compute tests passed!" << std::endl;
    
    return 0;
}
