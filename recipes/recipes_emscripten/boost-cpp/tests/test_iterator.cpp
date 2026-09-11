// Functional test for boost-iterator, adapted from
// libs/iterator/example/counting_iterator_example.cpp and
// libs/iterator/test/filter_iterator_test.cpp

#include <boost/iterator/counting_iterator.hpp>
#include <boost/iterator/filter_iterator.hpp>
#include <boost/iterator/transform_iterator.hpp>
#include <vector>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x "\n"; return 1; } } while (0)

struct is_even
{
    bool operator()(int x) const { return x % 2 == 0; }
};

int double_it(int x) { return 2 * x; }

int main()
{
    // counting_iterator generates the sequence [0, 10)
    std::vector<int> numbers;
    std::copy(boost::counting_iterator<int>(0),
              boost::counting_iterator<int>(10),
              std::back_inserter(numbers));
    CHECK(numbers.size() == 10);
    CHECK(numbers[0] == 0);
    CHECK(numbers[9] == 9);

    // filter_iterator only visits elements satisfying the predicate
    std::vector<int> evens;
    std::copy(boost::make_filter_iterator(is_even(), numbers.begin(), numbers.end()),
              boost::make_filter_iterator(is_even(), numbers.end(), numbers.end()),
              std::back_inserter(evens));
    CHECK(evens.size() == 5);
    CHECK(evens[0] == 0);
    CHECK(evens[4] == 8);

    // transform_iterator maps every element
    std::vector<int> doubled;
    std::copy(boost::make_transform_iterator(numbers.begin(), &double_it),
              boost::make_transform_iterator(numbers.end(), &double_it),
              std::back_inserter(doubled));
    CHECK(doubled.size() == 10);
    CHECK(doubled[0] == 0);
    CHECK(doubled[4] == 8);
    CHECK(doubled[9] == 18);
    std::cout << "boost-iterator OK\n";
    return 0;
}
