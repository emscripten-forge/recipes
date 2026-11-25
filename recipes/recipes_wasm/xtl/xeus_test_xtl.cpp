#include <cassert>
#include <iostream>
#include <xtl/xoptional.hpp>
#include <xtl/xtl_config.hpp>

void test_xtl()
{
    std::cout << "xtl " << XTL_VERSION_MAJOR << "." << XTL_VERSION_MINOR << "."
              << XTL_VERSION_PATCH << std::endl;

    xtl::xoptional<double> value = 3.0;
    assert(value.has_value());
    assert(value.value() == 3.0);

    auto missing = xtl::missing<double>();
    assert(!missing.has_value());
}

test_xtl();
