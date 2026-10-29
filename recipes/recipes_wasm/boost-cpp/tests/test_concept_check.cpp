// Functional test for boost-concept_check, adapted from
// libs/concept_check/test/stl_concept_check.cpp
#include <boost/concept_check.hpp>
#include <algorithm>
#include <deque>
#include <iostream>
#include <list>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    using namespace boost;

    typedef std::vector<int> Vector;
    typedef std::deque<int> Deque;
    typedef std::list<int> List;

    function_requires<Mutable_RandomAccessContainer<Vector> >();
    function_requires<BackInsertionSequence<Vector> >();
    function_requires<Mutable_RandomAccessContainer<Deque> >();
    function_requires<FrontInsertionSequence<Deque> >();
    function_requires<BackInsertionSequence<Deque> >();
    function_requires<Mutable_ReversibleContainer<List> >();
    function_requires<FrontInsertionSequence<List> >();
    function_requires<BackInsertionSequence<List> >();

    BOOST_CONCEPT_ASSERT((boost::RandomAccessIterator<Vector::iterator>));
    BOOST_CONCEPT_ASSERT((boost::EqualityComparable<int>));

    Vector v;
    v.push_back(3);
    v.push_back(1);
    v.push_back(2);
    std::sort(v.begin(), v.end());
    CHECK(v[0] == 1 && v[1] == 2 && v[2] == 3);

    List l;
    l.push_front(1);
    l.push_back(2);
    CHECK(l.front() == 1 && l.back() == 2);

    std::cout << "boost-concept_check OK\n";
    return 0;
}
