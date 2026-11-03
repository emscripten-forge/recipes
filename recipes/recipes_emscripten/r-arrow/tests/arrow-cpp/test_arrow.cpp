#include <iostream>
#include <arrow/api.h>
#include <arrow/type.h>

int main() {
    std::cout << "Testing Arrow C++ library..." << std::endl;
    
    // Test version
    auto version = arrow::GetBuildInfo();
    std::cout << "Arrow version: " << version.version_string << std::endl;
    
    // Create a simple schema (this is lightweight and doesn't allocate arrays)
    auto schema = arrow::schema({
        arrow::field("id", arrow::int64()),
        arrow::field("value", arrow::float64())
    });
    
    std::cout << "Created schema with " << schema->num_fields() << " fields" << std::endl;
    
    // Verify schema fields
    if (schema->num_fields() != 2) {
        std::cerr << "Test failed: Expected 2 fields, got " << schema->num_fields() << std::endl;
        return 1;
    }
    
    std::cout << "All Arrow C++ tests passed!" << std::endl;
    
    return 0;
}
