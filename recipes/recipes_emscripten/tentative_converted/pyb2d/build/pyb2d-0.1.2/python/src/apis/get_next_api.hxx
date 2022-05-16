namespace py = pybind11;

template<class CLS, class PY_CLS>
void add_get_next_api(PY_CLS & py_cls)
{
    py_cls
        .def("_has_next", [](CLS * self)
        {
            auto next = self->GetNext();
            return next != nullptr;
        })
        .def("_get_next", [](CLS * self)
        {
            auto next = self->GetNext();
            return next;
        }, py::return_value_policy::reference_internal)
    ;
}