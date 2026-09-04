#include <pybind11/pybind11.h>
namespace py = pybind11;

void init_pywrap_litert_compiled_model_wrapper(py::module_& m);
void init_pywrap_litert_environment_wrapper(py::module_& m);
void init_pywrap_litert_tensor_buffer_wrapper(py::module_& m);

PYBIND11_MODULE(_ai_edge_litert, m) {
  auto m_cm = m.def_submodule("_pywrap_litert_compiled_model_wrapper");
  init_pywrap_litert_compiled_model_wrapper(m_cm);
  auto m_env = m.def_submodule("_pywrap_litert_environment_wrapper");
  init_pywrap_litert_environment_wrapper(m_env);
  auto m_tb = m.def_submodule("_pywrap_litert_tensor_buffer_wrapper");
  init_pywrap_litert_tensor_buffer_wrapper(m_tb);
}