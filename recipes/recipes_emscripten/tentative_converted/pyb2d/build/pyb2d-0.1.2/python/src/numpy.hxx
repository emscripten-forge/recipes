#pragma once


#include <pybind11/numpy.h>
#include <initializer_list>
#include <vector>

namespace py = pybind11;

template<class T>
py::array_t<T> make_numpy_array(
    std::initializer_list<int> shape
)
{
    const std::size_t n_dim = shape.size();
    std::vector<int> shape_vec(shape);
    std::vector<int> stride_vec(n_dim);
    stride_vec.back() = sizeof(T);
    for(int i = n_dim - 2; i>=0; --i)
    {
        stride_vec[i] = shape_vec[i+1] * stride_vec[i+1];
    }

    return py::array(py::buffer_info(
        nullptr,         /* Pointer to data (nullptr -> ask NumPy to allocate!) */
        sizeof(T),     /* Size of one item */
        py::format_descriptor<T>::value, /* Buffer format */
        n_dim,          /* How many dimensions? */
        shape,  /* Number of elements for each dimension */
        stride_vec  /* Strides for each dimension */
    ));
}

template<class T>
auto np_view(T * ptr,  const std::vector<std::size_t> & shape)
{
    std::vector<std::size_t> strides(shape.size());

    std::size_t data_size = 1;
    for (std::size_t i = shape.size(); i != 0; --i)
    {
        strides[i - 1] = data_size;
        data_size = strides[i - 1] * shape[i - 1];
    }

    for(auto & s : strides)
    {
        s *= sizeof(T);
    }

    return py::array(py::buffer_info(
        ptr,                             /* Pointer to data (nullptr -> ask NumPy to allocate!) */
        sizeof(T),                       /* Size of one item */
        py::format_descriptor<T>::value, /* Buffer format */
        shape.size(),                    /* How many dimensions? */
        shape,                           /* Number of elements for each dimension */
        strides                          /* Strides for each dimension */
    ));
}


template<class T>
auto np_view(T * ptr,  const std::vector<std::size_t> & shape, const std::vector<std::size_t> & strides)
{
    return py::array(py::buffer_info(
        ptr,                             /* Pointer to data (nullptr -> ask NumPy to allocate!) */
        sizeof(T),                       /* Size of one item */
        py::format_descriptor<T>::value, /* Buffer format */
        shape.size(),                    /* How many dimensions? */
        shape,                           /* Number of elements for each dimension */
        strides                          /* Strides for each dimension */
    ));
}
