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
    code_stream <<"os.chdir('"<<testdir<<"');";



    try{
        py::exec("import os", scope);
        py::exec("import pytest", scope);
        py::exec(code_stream.str().c_str(), scope);

        #ifdef PYTEST_DRIVER_NODE
        py::exec("os.environ['PYTEST_DRIVER_NODE'] = '1'", scope);
        #else
        py::exec("os.environ['PYTEST_DRIVER_BROWSER'] = '1'", scope);
        #endif





        // #ifdef PYTEST_DRIVER_NODE
        // py::eval("import os;os.environ['PYTEST_DRIVER_NODE'] = '1';os.environ['PYTEST_DRIVER_BROWSER'] = '0'", scope);
        // #else
        // py::eval("import os;os.environ['PYTEST_DRIVER_NODE'] = '0';os.environ['PYTEST_DRIVER_BROWSER'] = '1'", scope);
        // #endif
    
        py::exec(code_stream.str().c_str(), scope);
        auto ret = py::eval("pytest.main(['-s'])", scope);
        return ret.cast<int>();
    }
    catch (py::error_already_set& e)
    {
        std::cout<<"error: "<<e.what()<<"\n";
        return -1;
    }
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
