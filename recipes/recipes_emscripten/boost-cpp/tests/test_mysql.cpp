// Functional test for boost-mysql , adapted from the SQL value
// types exercised by libs/mysql/test 

#include <boost/mysql/date.hpp>
#include <boost/mysql/datetime.hpp>
#include <boost/mysql/field.hpp>
#include <iostream>
#include <string>

#define CHECK(x) do { if (!(x)) { std::cerr << "FAIL: " #x << "\n"; return 1; } } while (0)

int main()
{
    // DATE: 2024 is a leap year, 2023 is not.
    boost::mysql::date leap(2024, 2, 29);
    CHECK(leap.valid());
    CHECK(leap.year() == 2024 && leap.month() == 2 && leap.day() == 29);
    boost::mysql::date invalid(2023, 2, 29);
    CHECK(!invalid.valid());
    boost::mysql::date d0;
    CHECK(!d0.valid());

    // DATETIME carries time-of-day down to microseconds.
    boost::mysql::datetime dt(2024, 2, 29, 23, 59, 58, 123456);
    CHECK(dt.valid());
    CHECK(dt.hour() == 23 && dt.minute() == 59 && dt.second() == 58);
    CHECK(dt.microsecond() == 123456);
    boost::mysql::datetime bad_hour(2024, 1, 1, 24, 0, 0, 0);
    CHECK(!bad_hour.valid());

    // FIELD: type-tagged SQL value with checked accessors.
    boost::mysql::field fint(42);
    CHECK(fint.is_int64() && fint.as_int64() == 42);
    boost::mysql::field fstr(std::string("hello"));
    CHECK(fstr.is_string() && fstr.as_string() == "hello");
    boost::mysql::field fdate(leap);
    CHECK(fdate.is_date() && fdate.as_date() == leap);
    boost::mysql::field fblob(boost::mysql::blob{1, 2, 3});
    CHECK(fblob.is_blob() && fblob.as_blob().size() == 3u && fblob.as_blob()[2] == 3);
    boost::mysql::field fnull(nullptr);
    CHECK(fnull.is_null());
    // field<->field_view round trip keeps the value.
    boost::mysql::field_view view = fstr;
    CHECK(view.is_string() && view.as_string() == "hello");
    boost::mysql::field copied(view);
    CHECK(copied.is_string() && copied.as_string() == "hello");

    std::cout << "boost-mysql OK\n";
    return 0;
}
