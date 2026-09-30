// Functional test for boost-openmethod, adapted from
// libs/openmethod/test/test_static_rtti.cpp

#include <boost/openmethod/default_registry.hpp>
#include <boost/openmethod/policies/static_rtti.hpp>

struct static_registry
    : boost::openmethod::registry<boost::openmethod::policies::static_rtti> {};

#define BOOST_OPENMETHOD_DEFAULT_REGISTRY static_registry

#include <boost/openmethod.hpp>
#include <boost/openmethod/interop/std_unique_ptr.hpp>
#include <boost/openmethod/initialize.hpp>
#include <iostream>
#include <sstream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

struct Animal {};
struct Dog : Animal {};
struct Cat : Animal {};

using namespace boost::openmethod::aliases;

BOOST_OPENMETHOD_CLASSES(Animal, Dog, Cat);

BOOST_OPENMETHOD(poke, (virtual_ptr<Animal>, std::ostream&), void);

BOOST_OPENMETHOD_OVERRIDE(poke, (virtual_ptr<Animal>, std::ostream& os), void) {
    os << "?";
}

BOOST_OPENMETHOD_OVERRIDE(poke, (virtual_ptr<Dog>, std::ostream& os), void) {
    os << "bark";
}

BOOST_OPENMETHOD_OVERRIDE(poke, (virtual_ptr<Cat>, std::ostream& os), void) {
    os << "hiss";
}

int main()
{
    boost::openmethod::initialize();

    auto cat = make_unique_virtual<Cat>();
    auto dog = make_unique_virtual<Dog>();
    auto animal = make_unique_virtual<Animal>();

    std::ostringstream os;
    poke(cat, os);
    CHECK(os.str() == "hiss");
    os.str("");
    poke(dog, os);
    CHECK(os.str() == "bark");
    os.str("");
    poke(animal, os);   // falls back to the base-class override
    CHECK(os.str() == "?");

    std::cout << "boost-openmethod OK\n";
    return 0;
}
