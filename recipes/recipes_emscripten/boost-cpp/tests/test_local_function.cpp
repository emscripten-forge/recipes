// Functional test for boost-local_function, adapted from
// libs/local_function/test/add.cpp

#include <boost/local_function.hpp>
#include <algorithm>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main(void)
{
    int sum = 0, factor = 10;               // Variables in scope to bind.

    void BOOST_LOCAL_FUNCTION(const bind factor, bind& sum, int num) {
        sum += factor * num;
    } BOOST_LOCAL_FUNCTION_NAME(add)

    add(1);                                 // Call the local function.
    int nums[] = {2, 3};
    std::for_each(nums, nums + 2, add);     // Pass it to an algorithm.
    CHECK(sum == 60);

    int BOOST_LOCAL_FUNCTION(const bind factor, int a) {
        return factor * a;
    } BOOST_LOCAL_FUNCTION_NAME(mul)
    CHECK(mul(2) == 20);
    CHECK(mul(5) == 50);
    std::cout << "boost-local_function OK\n";
    return 0;
}
