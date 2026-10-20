#include <oneapi/dpl/algorithm>
#include <oneapi/dpl/execution>
#include <oneapi/dpl/numeric>
#include <vector>
#include <iostream>
#include <cassert>

int main() {
    // Test 1: parallel_for with TBB backend
    std::cout << "Test 1: parallel_for..." << std::endl;
    std::vector<int> data(100, 0);
    auto policy = oneapi::dpl::execution::par_unseq;
    std::for_each(policy, data.begin(), data.end(), [](int& x) {
        x = 42;
    });
    for (int i = 0; i < 100; ++i) {
        assert(data[i] == 42);
    }
    std::cout << "  PASSED" << std::endl;

    // Test 2: parallel transform
    std::cout << "Test 2: transform..." << std::endl;
    std::vector<int> input(50), output(50);
    for (int i = 0; i < 50; ++i) {
        input[i] = i;
    }
    std::transform(policy, input.begin(), input.end(), output.begin(), [](int x) {
        return x * 2;
    });
    for (int i = 0; i < 50; ++i) {
        assert(output[i] == i * 2);
    }
    std::cout << "  PASSED" << std::endl;

    // Test 3: parallel reduce
    std::cout << "Test 3: reduce..." << std::endl;
    std::vector<int> nums(100);
    for (int i = 0; i < 100; ++i) {
        nums[i] = i + 1;
    }
    int sum = std::reduce(policy, nums.begin(), nums.end());
    int expected = (100 * 101) / 2;  // 1+2+...+100
    assert(sum == expected);
    std::cout << "  Sum: " << sum << " (expected: " << expected << ")" << std::endl;
    std::cout << "  PASSED" << std::endl;

    // Test 4: parallel sort
    std::cout << "Test 4: sort..." << std::endl;
    std::vector<int> unsorted = {5, 3, 8, 1, 9, 2, 7, 4, 6, 0};
    std::sort(policy, unsorted.begin(), unsorted.end());
    for (int i = 0; i < 10; ++i) {
        assert(unsorted[i] == i);
    }
    std::cout << "  PASSED" << std::endl;

    std::cout << "\nAll oneDPL tests passed!" << std::endl;
    return 0;
}
