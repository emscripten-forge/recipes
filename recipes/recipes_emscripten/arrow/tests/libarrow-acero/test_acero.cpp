#include <iostream>
#include <arrow/api.h>
#include <arrow/acero/api.h>

int main() {
    std::cout << "Testing Arrow Acero library..." << std::endl;
    
    // Create a simple schema (lightweight test)
    auto schema = arrow::schema({
        arrow::field("x", arrow::int64()),
        arrow::field("y", arrow::int64())
    });
    
    std::cout << "Created Acero schema with " << schema->num_fields() << " fields" << std::endl;
    
    // Test ExecPlan creation (basic functionality)
    auto plan_result = arrow::acero::ExecPlan::Make();
    if (!plan_result.ok()) {
        std::cerr << "Failed to create ExecPlan: " << plan_result.status().ToString() << std::endl;
        return 1;
    }
    
    auto plan = plan_result.ValueOrDie();
    std::cout << "Successfully created ExecPlan" << std::endl;
    
    // Validate plan is valid
    if (!plan) {
        std::cerr << "Test failed: ExecPlan is null" << std::endl;
        return 1;
    }
    
    std::cout << "ExecPlan validated successfully" << std::endl;
    std::cout << "All Acero tests passed!" << std::endl;
    
    return 0;
}
