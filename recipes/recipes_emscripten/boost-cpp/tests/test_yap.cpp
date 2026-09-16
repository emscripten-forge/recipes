// Functional test for boost-yap (header-only), adapted from
// libs/yap/example/calc2a.cpp

#include <boost/yap/yap.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

template <boost::yap::expr_kind Kind, typename Tuple>
struct minimal_expr
{
    static const boost::yap::expr_kind kind = Kind;
    Tuple elements;
};

int main()
{
    using namespace boost::yap::literals;

    // build expression trees with placeholders, evaluate with arguments
    auto expr_1 = 1_p + 2.0;
    CHECK(boost::yap::evaluate(expr_1, 3.0) == 5.0);

    auto expr_2 = 1_p * 2_p;
    CHECK(boost::yap::evaluate(expr_2, 3.0, 2.0) == 6.0);

    auto expr_3 = (1_p - 2_p) / 2_p;
    CHECK(boost::yap::evaluate(expr_3, 3.0, 2.0) == 0.5);

    // manual AST construction evaluates without arguments
    auto left = boost::yap::make_terminal<minimal_expr>(1);
    auto right = boost::yap::make_terminal<minimal_expr>(41);
    auto expr = boost::yap::make_expression<minimal_expr, boost::yap::expr_kind::plus>(left, right);
    CHECK(boost::yap::evaluate(expr) == 42);

    std::cout << "boost-yap OK\n";
    return 0;
}
