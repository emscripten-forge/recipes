#include <pybind11/embed.h> 
#include <emscripten/bind.h>
#include <pyjs/export_pyjs_module.hpp>
#include <pyjs/export_js_module.hpp>
#include <sstream>


namespace py = pybind11;
namespace em = emscripten;

int run_tests(const std::string & testdir)
{
    py::object scope = py::module_::import("__main__").attr("__dict__");
    std::stringstream code_stream;
    code_stream <<"import os; import pytest; os.chdir('"<<testdir<<"');";
    py::exec(code_stream.str().c_str(), scope);
    auto ret = py::eval("pytest.main(['-s'])", scope);
    return ret.cast<int>();
}

PYBIND11_EMBEDDED_MODULE(pyjs, m) {
    pyjs::export_pyjs_module(m);
}

EMSCRIPTEN_BINDINGS(my_module) {
    
    pyjs::export_js_module();

    em::function("run_tests", &run_tests);
    em::function("initialize_interpreter",em::select_overload<void()>([](){
        py::initialize_interpreter(true,0,nullptr,false);
    }));
    em::function("finalize_interpreter",em::select_overload<void()>([](){
        py::finalize_interpreter();
    }));
}
