#include <thrift/Thrift.h>
#include <thrift/protocol/TBinaryProtocol.h>
#include <thrift/transport/TBufferTransports.h>
#include <iostream>
#include <string>

int main() {
    std::cout << "Testing Thrift C++ library..." << std::endl;
    
    // Test basic Thrift types
    try {
        using namespace apache::thrift;
        using namespace apache::thrift::protocol;
        using namespace apache::thrift::transport;
        
        // Create a memory buffer
        std::shared_ptr<TMemoryBuffer> buffer(new TMemoryBuffer());
        std::shared_ptr<TBinaryProtocol> protocol(new TBinaryProtocol(buffer));
        
        // Write some basic types
        protocol->writeI32(42);
        protocol->writeString(std::string("Hello, Thrift!"));
        protocol->writeBool(true);
        
        std::cout << "Successfully wrote data to Thrift protocol" << std::endl;
        
        // Read back the data
        int32_t i32_value;
        std::string str_value;
        bool bool_value;
        
        protocol->readI32(i32_value);
        protocol->readString(str_value);
        protocol->readBool(bool_value);
        
        std::cout << "Read values: " << i32_value << ", " << str_value << ", " << bool_value << std::endl;
        
        // Verify values
        if (i32_value == 42 && str_value == "Hello, Thrift!" && bool_value == true) {
            std::cout << "Thrift C++ test passed!" << std::endl;
            return 0;
        } else {
            std::cerr << "Values mismatch!" << std::endl;
            return 1;
        }
        
    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
    
    return 0;
}
