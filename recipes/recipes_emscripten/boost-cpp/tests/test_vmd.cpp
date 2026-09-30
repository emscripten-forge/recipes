// Functional test for boost-vmd
// adapted from libs/vmd/test/test_seq_size.cxx.

#include <boost/vmd/vmd.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

#define A_SEQ (1)(2)(3)(4)
#define AN_EMPTY_SEQ

int main()
{
    // size of sequences (macro results expand to integer tokens)
    CHECK(BOOST_VMD_SEQ_SIZE(A_SEQ) == 4);
    CHECK(BOOST_VMD_SEQ_SIZE(AN_EMPTY_SEQ) == 0);

    // predicates classify preprocessor data structures
    CHECK(BOOST_VMD_IS_SEQ(A_SEQ) == 1);
    CHECK(BOOST_VMD_IS_SEQ((a, b)) == 0);      // a tuple, not a seq
    CHECK(BOOST_VMD_IS_TUPLE((a, b)) == 1);
    CHECK(BOOST_VMD_IS_NUMBER(42) == 1);
    CHECK(BOOST_VMD_IS_NUMBER(alpha) == 0);

    std::cout << "boost-vmd OK\n";
    return 0;
}
