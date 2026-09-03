#include <boost/python.hpp>

int add(int a, int b) { return a + b; }

BOOST_PYTHON_MODULE(_test_boost_python) {
    boost::python::def("add", &add);
}
