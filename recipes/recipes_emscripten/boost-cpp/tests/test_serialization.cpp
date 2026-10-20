// Functional test for boost-serialization, adapted from
// libs/serialization/test/text_archive test pattern.

#include <boost/archive/text_oarchive.hpp>
#include <boost/archive/text_iarchive.hpp>
#include <boost/serialization/string.hpp>
#include <boost/serialization/vector.hpp>
#include <sstream>
#include <string>
#include <vector>
#include <iostream>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << std::endl; return 1; } } while (0)

struct Data
{
    int i = 0;
    double d = 0.0;
    std::string s;
    std::vector<int> v;

    template <class Archive>
    void serialize(Archive& ar, unsigned /*version*/)
    {
        ar& i& d& s& v;
    }
};

static bool roundtrip(Data const& in, Data& out)
{
    std::ostringstream os;
    {
        boost::archive::text_oarchive oa(os);
        oa << in;
    }
    std::istringstream is(os.str());
    boost::archive::text_iarchive ia(is);
    ia >> out;
    return true;
}

int main()
{
    Data a;
    a.i = 42;
    a.d = 3.14159;
    a.s = "boost serialization";
    a.v = {1, -2, 3, 1000};

    std::string archive;
    {
        std::ostringstream os;
        {
            boost::archive::text_oarchive oa(os);
            oa << a;
        }
        archive = os.str();
        CHECK(!archive.empty());
        // text archives are human-readable: must contain the values
        CHECK(archive.find("42") != std::string::npos);
        CHECK(archive.find("serialization") != std::string::npos);
    }

    Data b;
    {
        std::istringstream is(archive);
        boost::archive::text_iarchive ia(is);
        ia >> b;
    }
    CHECK(b.i == a.i);
    CHECK(b.d == a.d);
    CHECK(b.s == a.s);
    CHECK(b.v == a.v);

    // a second object in the same archive stream (stream state must not bleed)
    Data c;
    c.i = 7;
    c.s = "second";
    Data c2;
    {
        std::ostringstream os;
        {
            boost::archive::text_oarchive oa(os);
            oa << a;
            oa << c;
        }
        std::istringstream is(os.str());
        boost::archive::text_iarchive ia(is);
        ia >> b;
        ia >> c2;
    }
    CHECK(b.i == 42);
    CHECK(c2.i == 7);
    CHECK(c2.s == "second");

    std::cout << "boost-serialization OK" << std::endl;
    return 0;
}
