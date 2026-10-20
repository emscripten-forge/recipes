// Functional test for boost-property_map

#include <boost/property_map/property_map.hpp>
#include <iostream>
#include <map>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    std::map<std::string, std::string> name2address;
    boost::associative_property_map<std::map<std::string, std::string> > address_map(name2address);

    typedef boost::property_traits<boost::associative_property_map<std::map<std::string, std::string> > >::value_type value_type;
    typedef boost::property_traits<boost::associative_property_map<std::map<std::string, std::string> > >::key_type key_type;

    put(address_map, key_type("Fred"), value_type("710 West 13th Street"));
    put(address_map, key_type("Joe"), value_type("710 West 13th Street"));

    CHECK(get(address_map, key_type("Fred")) == value_type("710 West 13th Street"));

    // property-map put() writes through to the underlying map
    put(address_map, key_type("Fred"), value_type("384 Fitzpatrick Street"));
    CHECK(name2address["Fred"] == "384 Fitzpatrick Street");
    CHECK(get(address_map, key_type("Fred")) == value_type("384 Fitzpatrick Street"));

    // operator[] on the map exposes a writable reference
    address_map[key_type("Joe")] = value_type("325 Cushing Avenue");
    CHECK(name2address["Joe"] == "325 Cushing Avenue");

    // read-only property map view: writes are rejected at compile time
    boost::const_associative_property_map<std::map<std::string, std::string> > const_map(name2address);
    CHECK(get(const_map, key_type("Joe")) == value_type("325 Cushing Avenue"));

    std::cout << "boost-property_map OK\n";
    return 0;
}
