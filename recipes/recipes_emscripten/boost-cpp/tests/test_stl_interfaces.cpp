// Functional test for boost-stl_interfaces, adapted from
// libs/stl_interfaces/test/array.cpp

#include <boost/stl_interfaces/sequence_container_interface.hpp>
#include <boost/stl_interfaces/reverse_iterator.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

// A container defined from only begin/end/max_size: the CRTP base supplies
// size(), operator[], at(), comparisons, etc.
template< typename T, std::size_t N >
struct fixed_arr : boost::stl_interfaces::sequence_container_interface<
                       fixed_arr< T, N >,
                       boost::stl_interfaces::element_layout::contiguous >
{
    using value_type = T;
    using pointer = T*;
    using const_pointer = T const*;
    using reference = value_type&;
    using const_reference = value_type const&;
    using size_type = std::size_t;
    using difference_type = std::ptrdiff_t;
    using iterator = T*;
    using const_iterator = T const*;
    using reverse_iterator = boost::stl_interfaces::reverse_iterator< iterator >;
    using const_reverse_iterator =
        boost::stl_interfaces::reverse_iterator< const_iterator >;

    iterator begin() noexcept { return elements_; }
    iterator end() noexcept { return elements_ + N; }

    size_type max_size() const noexcept { return N; }

    using base_type = boost::stl_interfaces::sequence_container_interface<
        fixed_arr< T, N >,
        boost::stl_interfaces::element_layout::contiguous >;
    using base_type::begin;
    using base_type::end;

    T elements_[N];
};

int main()
{
    fixed_arr< int, 5 > sm;
    for (int i = 0; i < 5; ++i) sm[i] = i;
    fixed_arr< int, 5 > md;
    for (int i = 0; i < 5; ++i) md[i] = i + 1;

    CHECK(sm.size() == 5); // from the base, via begin/end
    CHECK(sm.max_size() == 5);
    CHECK(sm[2] == 2);
    sm[2] = 9;
    CHECK(sm[2] == 9);
    CHECK(sm.at(0) == 0);
    CHECK(sm == sm);
    CHECK(!(sm == md));
    CHECK(sm != md);
    CHECK(sm < md); // lexicographic ordering from the base

    int sum = 0;
    for (int x : md) sum += x; // range-for via base begin/end
    CHECK(sum == 15);

    std::cout << "boost-stl_interfaces OK\n";
    return 0;
}
