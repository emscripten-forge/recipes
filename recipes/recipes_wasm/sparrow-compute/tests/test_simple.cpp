#include <cmath>
#include <cstddef>
#include <iostream>

#include <sparrow/primitive_array.hpp>

#include <sparrow-compute.hpp>

int main()
{
    sparrow::primitive_array<double> a{1.0, 4.0, 9.0};
    sparrow::primitive_array<double> b{1.0, 4.0, 9.0};

    const auto result = sparrow::compute::eval(sparrow::compute::sqrt((a + b) / 2.0));
    const double expected[] = {1.0, 2.0, 3.0};

    for (std::size_t i = 0; i < result.size(); ++i)
    {
        const double value = result[i].value();
        if (std::abs(value - expected[i]) > 1e-12)
        {
            std::cerr << "unexpected value at index " << i << ": " << value << '\n';
            return 1;
        }
    }

    std::cout << "sparrow-compute test passed\n";
    return 0;
}
