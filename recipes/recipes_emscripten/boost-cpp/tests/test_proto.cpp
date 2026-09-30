// Functional test for boost-proto , adapted from
// libs/proto/example/calc1.cpp

#include <boost/proto/proto.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

namespace proto = boost::proto;
using proto::_;

template<int I> struct placeholder {};

// Placeholder terminal objects: _1 and _2 bind to context values.
proto::terminal<placeholder<1>>::type const _1 = {{}};
proto::terminal<placeholder<2>>::type const _2 = {{}};

// Calculator context: evaluates arithmetic expressions of doubles.
struct calculator_context
  : proto::callable_context<calculator_context const>
{
    double d[2];
    typedef double result_type;

    explicit calculator_context(double d1 = 0., double d2 = 0.)
    {
        d[0] = d1;
        d[1] = d2;
    }

    template<int I>
    double operator()(proto::tag::terminal, placeholder<I>) const
    {
        return d[I - 1];
    }
};

template<typename Expr>
double evaluate(Expr const& expr, double d1 = 0., double d2 = 0.)
{
    calculator_context const ctx(d1, d2);
    return proto::eval(expr, ctx);
}

int main()
{
    CHECK(evaluate(_1 + 2.0, 3.0) == 5.0);        // placeholder + literal
    CHECK(evaluate(_1 * _2, 3.0, 2.0) == 6.0);     // two placeholders
    CHECK(evaluate((_1 - _2) / _2, 3.0, 2.0) == 0.5);
    CHECK(evaluate((_1 + _2) * _1, 3.0, 2.0) == 15.0); // nested sub-expressions

    std::cout << "boost-proto OK\n";
    return 0;
}
