#include <antlr4-runtime.h>
#include <iostream>

int main() {
    // Create an ANTLR input stream from a string
    antlr4::ANTLRInputStream input("hello world");

    // Verify basic properties
    if (input.size() != 11) {
        std::cerr << "FAIL: expected size 11, got " << input.size() << std::endl;
        return 1;
    }

    // Check that we can read characters
    std::string consumed;
    for (size_t i = 0; i < input.size(); ++i) {
        consumed += input.LA(static_cast<ssize_t>(i + 1));
    }
    if (consumed != "hello world") {
        std::cerr << "FAIL: expected 'hello world', got '" << consumed << "'" << std::endl;
        return 1;
    }

    // Test reset and index tracking
    input.reset();
    if (input.index() != 0) {
        std::cerr << "FAIL: expected index 0 after reset, got " << input.index() << std::endl;
        return 1;
    }

    std::cout << "ANTLR4 runtime test passed!" << std::endl;
    return 0;
}
