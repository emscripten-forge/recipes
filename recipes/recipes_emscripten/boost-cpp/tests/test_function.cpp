#include <boost/function.hpp>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static int triple(int x) { return x * 3; }

int main()
{
    boost::function<int(int)> f;
    CHECK(f.empty());                    // default-constructed is empty

    f = &triple;                         // assign a plain function pointer
    CHECK(!f.empty());
    CHECK(f(7) == 21);

    boost::function<int(int)> g = f;     // copy
    CHECK(g(4) == 12);

    f = [](int x) { return x + 1; };     // assign a lambda
    CHECK(f(41) == 42);

    f.clear();                           // back to empty, callable check only
    CHECK(f.empty());

    std::cout << "boost-function OK\n";
    return 0;
}
