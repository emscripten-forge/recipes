#include <iostream>
#include <sparrow/config/sparrow_version.hpp>
#include "sparrow/primitive_array.hpp"

int main() {
    std::cout << "Testing sparrow library..." << std::endl;
    
    // Test version constants
    std::cout << "sparrow version: " 
              << sparrow::SPARROW_VERSION_MAJOR << "."
              << sparrow::SPARROW_VERSION_MINOR << "."
              << sparrow::SPARROW_VERSION_PATCH << std::endl;
    
    sparrow::primitive_array<int> arr{1, 2, 3, 4, 5};
    for(size_t i = 0; i < arr.size(); ++i) {
        if(arr[i] != static_cast<int>(i + 1)) {
            std::cerr << "Test failed: arr[" << i << "] = " << arr[i] 
                      << ", expected " << (i + 1) << std::endl;
            return 1;
        }
    }
    std::cout << "All tests passed!" << std::endl;
    return 0;
}
