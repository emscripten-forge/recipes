// Functional test for boost-locale, adapted from
// libs/locale/test/test_utf.cpp


#include <boost/locale/encoding.hpp>
#include <string>

int main()
{
    // "café € 42" in UTF-8
    std::string utf8 = "caf\xc3\xa9 \xe2\x82\xac 42";

    // UTF-8 -> wchar_t -> UTF-8 roundtrip (wchar_t = 4 bytes on wasm)
    std::wstring wide = boost::locale::conv::utf_to_utf<wchar_t>(utf8);
    if (wide.empty()) return 1;
    if (boost::locale::conv::utf_to_utf<char>(wide) != utf8)
        return 1;

    // explicit encoding names roundtrip
    if (boost::locale::conv::from_utf(wide, "UTF-8") != utf8)
        return 1;
    if (boost::locale::conv::to_utf<wchar_t>(utf8, "UTF-8") != wide)
        return 1;

    return 0;
}
