#include <boost/python.hpp>
#include <stdexcept>
#include <string>

int add(int a, int b) {
    return a + b;
}

void raise_value_error(const std::string& msg) {
    throw std::invalid_argument(msg);
}

static void translate_invalid_argument(const std::invalid_argument& e) {
    PyErr_SetString(PyExc_ValueError, e.what());
}

BOOST_PYTHON_MODULE(mymodule) {
    using namespace boost::python;
    def("add", add);
    def("raise_value_error", raise_value_error);
    register_exception_translator<std::invalid_argument>(&translate_invalid_argument);
}
