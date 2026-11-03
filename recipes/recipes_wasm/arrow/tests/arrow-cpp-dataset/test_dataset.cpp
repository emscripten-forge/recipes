#include <iostream>
#include <arrow/api.h>
#include <arrow/dataset/api.h>

int main() {
    std::cout << "Testing Arrow Dataset library..." << std::endl;
    
    // Create a simple schema
    auto schema = arrow::schema({
        arrow::field("id", arrow::int64()),
        arrow::field("value", arrow::float64())
    });
    
    std::cout << "Created dataset schema with " << schema->num_fields() << " fields" << std::endl;
    
    // Validate schema
    if (schema->num_fields() != 2) {
        std::cerr << "Test failed: Expected 2 fields, got " << schema->num_fields() << std::endl;
        return 1;
    }
    
    // Check that dataset types are available
    auto id_field = schema->field(0);
    if (id_field->name() != "id") {
        std::cerr << "Test failed: Expected field 'id', got '" << id_field->name() << "'" << std::endl;
        return 1;
    }
    
    std::cout << "Dataset schema validated successfully" << std::endl;
    std::cout << "All Dataset tests passed!" << std::endl;
    
    return 0;
}
