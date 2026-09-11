// Functional test for boost-multi_array, adapted from
// libs/multi_array/test/constructors.cpp and access.cpp.

#include <boost/multi_array.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    typedef boost::multi_array<double, 3> array3;
    array3 A(boost::extents[2][3][4]);

    CHECK(A.num_dimensions() == 3);
    CHECK(A.shape()[0] == 2 && A.shape()[1] == 3 && A.shape()[2] == 4);
    CHECK(A.num_elements() == 24u);

    // Fill every element and read it back.
    for (unsigned i = 0; i < 2; ++i)
        for (unsigned j = 0; j < 3; ++j)
            for (unsigned k = 0; k < 4; ++k)
                A[i][j][k] = 100.0 * i + 10.0 * j + k;
    CHECK(A[1][2][3] == 123.0);

    double sum = 0.0;
    for (unsigned n = 0; n < A.num_elements(); ++n)
        sum += A.data()[n];
    CHECK(sum == 1476.0);  // 1200 + 240 + 36

    // resize() keeps existing elements whose indices stay valid.
    A.resize(boost::extents[2][4][4]);
    CHECK(A.shape()[1] == 4 && A.num_elements() == 32u);
    CHECK(A[1][2][3] == 123.0);
    CHECK(A[1][3][3] == 0.0);  // new storage is value-initialized

    std::cout << "boost-multi_array OK\n";
    return 0;
}
