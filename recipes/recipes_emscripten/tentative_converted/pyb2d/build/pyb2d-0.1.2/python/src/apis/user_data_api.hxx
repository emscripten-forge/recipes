#pragma once

#include <pybind11/pybind11.h>
#include <iostream> 

#include "../box2d_wrapper.hpp"


class UserData
{   
public:
    UserData()
    :   m_int_data(),
        m_has_int_data(false),
        m_object_data(),
        m_has_object_data(false)
    {

    }

    void clear_int_data()
    {
        m_has_int_data = false;
    }
    void clear_object_data()
    {
        m_has_object_data = false;
        m_object_data = pybind11::object();
    }

    bool has_int_data() const
    {
        return m_has_int_data;
    }
    void set_int_data(const int64_t int_data)
    {
        m_has_int_data = true;
        m_int_data = int_data;
    }
    int64_t get_int_data() const
    {
        return m_int_data;
    }

    bool has_object_data() const
    {
        return m_has_object_data;
    }
    void set_object_data(pybind11::object arbitrary_data)
    {
        m_has_object_data = true;
        m_object_data = arbitrary_data;
    }
    pybind11::object get_object_data() const
    {
        return m_object_data;
    }
private:
    int64_t m_int_data;
    bool m_has_int_data; 
    pybind11::object m_object_data;
    bool m_has_object_data;
};


template<class ENTITY>
inline void delete_user_data_if_has_user_data(ENTITY * entity)
{   

    void* ud = get_user_data(entity);
    if(ud != nullptr)
    {
        delete static_cast<UserData*>(ud);
    }
}


template<class B2_DEF_CLASS>
class PyDefExtender : public B2_DEF_CLASS
{
public:
    PyDefExtender(){}
    ~PyDefExtender(){
        void* ud = get_user_data_from_def(this);
        if(ud != nullptr)
        {
            delete static_cast<UserData*>(ud);
        }
    }

    void SetUserData(void* data){
        set_user_data_for_def(this, data);
    }
    // void *  GetUserData() {
    //     return get_user_data_from_def(this);
    // }
};




template<class CLS, class PY_CLS>
void add_user_data_api(PY_CLS & py_cls)
{
    py_cls
    .def_property_readonly("has_object_user_data",[](CLS * entity){

        void* vud = get_user_data(entity);
        if(vud != nullptr)
        {
            return static_cast< UserData * >(vud)->has_object_data();
        }
        return false;
    })


    .def("_set_object_user_data",[](CLS * entity, const pybind11::object & obj_ud){
        void* vud = get_user_data(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            ud->set_object_data(obj_ud);
        }
        else
        {
            UserData * ud = new UserData();
            set_user_data(entity, ud);
            ud->set_object_data(obj_ud);
        }
    })
    .def("_clear_object_user_data",[](CLS * entity){
        void* vud = get_user_data(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            ud->clear_object_data();
        }
    })

    .def("_get_object_user_data",[](CLS * entity){
        void* vud = get_user_data(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            return ud->get_object_data();
        }
        else
        {
            throw std::runtime_error("cannot _get_object_user_data, ud is NULLPTR");
        }
    })
    ;
}

template<class CLS, class PY_CLS>
void add_user_data_to_def_api(PY_CLS & py_cls)
{
    py_cls
    .def_property_readonly("has_object_user_data",[](CLS * entity){
        void* ud =  get_user_data_from_def(entity);
        if(ud != nullptr)
        {
            return static_cast< UserData * >(ud)->has_object_data();
        }
        return false;
    })


    .def("_set_object_user_data",[](CLS * entity, const pybind11::object & obj_ud){
        void* vud = get_user_data_from_def(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            ud->set_object_data(obj_ud);
        }
        else
        {
            UserData * ud = new UserData();
            set_user_data_for_def(entity, ud);
            ud->set_object_data(obj_ud);
        }
    })
    .def("_clear_object_user_data",[](CLS * entity){
        void* vud = get_user_data_from_def(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            ud->clear_object_data();
        }
    })


    .def("_get_object_user_data",[](CLS * entity){
        void* vud = get_user_data_from_def(entity);
        if(vud != nullptr)
        {
            UserData * ud =  static_cast< UserData * >(vud);
            return ud->get_object_data();
        }
        else
        {
            throw std::runtime_error("cannot _get_object_user_data, ud is NULLPTR");
        }
    })
    ;
}

template<class DEF, class ENTITY>
void set_user_data_from_def(const DEF * def, ENTITY * entity)
{
    void * void_ptr_def_user_data = get_user_data_from_def(def);
    if(void_ptr_def_user_data != nullptr)
    {
        UserData * def_user_data = static_cast<UserData*>(void_ptr_def_user_data);
        UserData * entity_user_data = new UserData(*def_user_data);

        set_user_data(entity, entity_user_data);
        //entity->GetUserData().pointer = reinterpret_cast<uintptr_t>(entity_user_data);
    }
}