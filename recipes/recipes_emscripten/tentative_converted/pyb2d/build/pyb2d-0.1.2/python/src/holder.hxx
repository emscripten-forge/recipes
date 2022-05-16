#pragma once

#include <pybind11/pybind11.h>
#include "box2d_wrapper.hpp"

template<class T>
class Holder
{
public:
    Holder(T * ptr)
    :   m_ptr(ptr)
    {

    }
    Holder(const T * ptr)
    :   m_ptr(const_cast<T*>(ptr))
    {

    }
    T * operator->() 
    {
        return this->get();
    }
    const T * operator->() const
    {
       return this->get();
    }

    T * get()  {
        return m_ptr;
    }
    const T * get() const {
        return m_ptr;
    }
private:
    T * m_ptr;
};

typedef Holder<b2Body>              BodyHolder;
typedef Holder<b2Fixture>           FixtureHolder;
typedef Holder<b2Joint>             JointHolder;
typedef Holder<b2DistanceJoint>     DistanceJointHolder;

typedef Holder<b2Shape>             ShapeHolder;
typedef Holder<b2Contact>           ContactHolder;
typedef Holder<b2Manifold>          ManifoldHolder;
typedef Holder<b2ContactImpulse>    ContactImpulseHolder;
#ifdef PYBOX2D_LIQUID_FUN
typedef Holder<b2ParticleSystem>    ParticleSystemHolder;
typedef Holder<b2ParticleGroup>     ParticleGroupHolder;
#endif
typedef Holder<b2WorldManifold>     WorldManifoldHolder;
typedef Holder<b2ContactImpulse>    ContactImpulseHolder;

PYBIND11_DECLARE_HOLDER_TYPE(T, Holder<T>, true);
