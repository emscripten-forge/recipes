#pragma once
#include "../box2d_wrapper.hpp"
#include <pybind11/pybind11.h>
#include "../pyb2WorldCallbacks.hxx"
#include <memory>
#include "../debug_draw/extended_debug_draw_base.hxx"



class PyWorld : public b2World
{
public:
    PyWorld(const b2Vec2& gravity)
    :   b2World(gravity),
        m_destruction_listener(new PyWorldDestructionListenerCaller()),
        p_extended_debug_draw(nullptr)
    {
        // install destruction listener
        this->SetDestructionListener(m_destruction_listener.get());
    }
    ~PyWorld(){
        for ( b2Body* b = this->GetBodyList(); b; b = b->GetNext())
        {
            delete_user_data_if_has_user_data(b);
        }
    }

    void set_py_destruction_listener(const py::object & object)
    {
        this->m_destruction_listener->set_py_destruction_listener(object);
    }

    void SetExtendedDebugDraw(ExtendedDebugDrawBase * extended_debug_draw)
    {   
        if(p_extended_debug_draw)
        {
            throw std::runtime_error("PyWorld has already a debug draw");
        }
        this->SetDebugDraw(extended_debug_draw);
        p_extended_debug_draw = extended_debug_draw;
    }
    #if PYBOX2D_OLD_BOX2D
    void DebugDraw(){
        return this->DrawDebugData();
    }
    #endif

    void ExtendedDebugDraw()
    {
        if(p_extended_debug_draw){
            p_extended_debug_draw->BeginDraw();
            if(p_extended_debug_draw->ReleaseGilWhileDebugDraw())
            {
                py::gil_scoped_release release;
                this->DebugDraw();
            }
            else
            {
                this->DebugDraw();
            }
            p_extended_debug_draw->EndDraw();
        }
    }


private:
    std::unique_ptr<PyWorldDestructionListenerCaller> m_destruction_listener;
    ExtendedDebugDrawBase  * p_extended_debug_draw;
};