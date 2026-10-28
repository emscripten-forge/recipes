#include <iostream>
#include <string>
#include <vector>

#include "iceberg/schema.h"
#include "iceberg/schema_field.h"
#include "iceberg/type.h"

int main() {
    iceberg::Schema schema({
        iceberg::SchemaField::MakeRequired(1, "id", iceberg::int32()),
        iceberg::SchemaField::MakeOptional(2, "name", iceberg::string()),
    });

    const auto highest_field_id = schema.HighestFieldId();
    if (!highest_field_id) {
        std::cerr << "Failed to compute highest field id: "
                  << highest_field_id.error().message << std::endl;
        return 1;
    }

    if (highest_field_id.value() != 2) {
        std::cerr << "Unexpected highest field id: " << highest_field_id.value() << std::endl;
        return 1;
    }

    const auto name_field = schema.FindFieldByName("name");
    if (!name_field) {
        std::cerr << "Failed to find field by name: " << name_field.error().message << std::endl;
        return 1;
    }

    if (!name_field.value().has_value()) {
        std::cerr << "Schema is missing expected field 'name'" << std::endl;
        return 1;
    }

    if (name_field.value()->get().field_id() != 2) {
        std::cerr << "Unexpected field id for 'name': "
                  << name_field.value()->get().field_id() << std::endl;
        return 1;
    }

    std::cout << "iceberg schema smoke test passed" << std::endl;
    return 0;
}