#include <ewah/ewah.h>
#include <iostream>

int main() {
    try {
        EWAHBoolArray<> bitmap;
        bitmap.set(0);
        bitmap.set(100);
        std::cout << "EWAH bool utils import test passed" << std::endl;
        return 0;
    } catch (...) {
        std::cout << "EWAH bool utils import test failed" << std::endl;
        return 1;
    }
}