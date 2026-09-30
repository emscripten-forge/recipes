// Functional test for boost-preprocessor,
// adapted from libs/preprocessor/test/arithmetic.cxx and facilities tests

#include <boost/preprocessor.hpp>
#include <cstring>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)
#define CHECK_STR(a, b) do { if (std::strcmp((a), (b)) != 0) { std::cerr << "FAIL: " #a << "\n"; return 1; } } while (0)

static_assert(BOOST_PP_ADD(2, 3) == 5, "add");
static_assert(BOOST_PP_ADD(BOOST_PP_ADD(2, 2), 2) == 6, "add-nested");
static_assert(BOOST_PP_SUB(10, 4) == 6, "sub");
static_assert(BOOST_PP_MUL(3, 4) == 12, "mul");
static_assert(BOOST_PP_INC(41) == 42, "inc");
static_assert(BOOST_PP_SEQ_SIZE((a)(b)(c)) == 3, "seq-size");

int BOOST_PP_CAT(my_, var) = 7;

int main()
{
    CHECK(BOOST_PP_ADD(2, 3) == 5);
    CHECK(my_var == 7); // BOOST_PP_CAT pasted the identifier
    CHECK_STR(BOOST_PP_STRINGIZE(hello world), "hello world");
    CHECK(BOOST_PP_IF(1, 10, 20) == 10);
    CHECK(BOOST_PP_IF(0, 10, 20) == 20);
    std::cout << "boost-preprocessor OK\n";
    return 0;
}
