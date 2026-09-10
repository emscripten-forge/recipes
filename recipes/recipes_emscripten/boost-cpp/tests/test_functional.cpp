// Functional test for boost-functional, adapted from
// libs/functional/test/function_test.cpp

#include <boost/functional.hpp>
#include <algorithm>
#include <iostream>
#include <string>
#include <vector>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

static bool is_betty(const std::string &s) { return s == "Betty"; }
static bool is_equal(const std::string &a, const std::string &b) { return a == b; }

struct Person
{
    std::string name;
    Person(const char *n) : name(n) {}
    bool is_fred() const { return name == "Fred"; }
};

int main()
{
    std::vector<std::string> v;
    v.push_back("Fred"); v.push_back("Wilma"); v.push_back("Barney"); v.push_back("Betty");

    // not1 (unary negate) on a plain function
    CHECK(std::count_if(v.begin(), v.end(), boost::not1(is_betty)) == 3);

    // bind1st / bind2nd on a binary function
    CHECK(boost::bind1st(is_equal, "Betty")(std::string("Betty")) == true);
    CHECK(boost::bind2nd(is_equal, "Betty")(std::string("Wilma")) == false);

    // mem_fun_ref on objects, mem_fun on pointers
    Person fred("Fred"), wilma("Wilma");
    CHECK(boost::mem_fun_ref(&Person::is_fred)(fred) == true);
    CHECK(boost::mem_fun_ref(&Person::is_fred)(wilma) == false);
    CHECK(boost::mem_fun(&Person::is_fred)(&fred) == true);
    CHECK(boost::mem_fun(&Person::is_fred)(&wilma) == false);

    std::cout << "boost-functional OK\n";
    return 0;
}
