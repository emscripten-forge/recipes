#pragma once

#include <iostream>
#include <pybind11/pybind11.h>

#include "box2d_wrapper.hpp"
#include "apis/user_data_api.hxx"
#include "holder.hxx"

namespace py = pybind11;






class PyWorldDestructionListenerCaller : public b2DestructionListener {
public:

    virtual ~PyWorldDestructionListenerCaller() {}

    PyWorldDestructionListenerCaller()
    :   object_(),
        m_has_obj(false)
    {
    }
    PyWorldDestructionListenerCaller(const py::object & object)
    :   object_(object),
        m_has_obj(bool(object_))
    {
    }

    void set_py_destruction_listener(const py::object & object)
    {
        object_ = object;
        m_has_obj = true;
    }

    void SayGoodbye(b2Joint * joint) override {
        if(m_has_obj)
        {
            py::object f = object_.attr("say_goodbye_joint");
            f(JointHolder(joint));
        }
        delete_user_data_if_has_user_data(joint);
    }
    void SayGoodbye(b2Fixture * fixture) override {

        if(m_has_obj)
        {
            py::object f = object_.attr("say_goodbye_fixture");
            f(FixtureHolder(fixture));
        }
        delete_user_data_if_has_user_data(fixture);
    }
    #ifdef PYBOX2D_LIQUID_FUN
    void SayGoodbye(b2ParticleGroup* group) override {
        if(m_has_obj)
        {
            py::object f = object_.attr("say_goodbye_particle_group");
            f(ParticleGroupHolder(group));
        }
        delete_user_data_if_has_user_data(group);
    }

    void SayGoodbye(b2ParticleSystem* particleSystem, int32 index) override {
        if(m_has_obj)
        {
            py::object f = object_.attr("say_goodbye_particle_System");
            f(ParticleSystemHolder(particleSystem), index);
        }
        // check me....
        //delete_user_data_if_has_user_data(group);

    }
    #endif
private:
    py::object object_;
    bool m_has_obj;
};




class PyB2DestructionListenerCaller : public b2DestructionListener {
public:
    /* Inherit the constructors */
    //using b2DestructionListener::b2DestructionListener;

    virtual ~PyB2DestructionListenerCaller() {}

    PyB2DestructionListenerCaller(const py::object & object)
    : object_(object){
    }
    virtual void SayGoodbye(b2Joint * joint)  {
        py::object f = object_.attr("say_goodbye_joint");
        f(JointHolder(joint));
    }
    virtual void SayGoodbye(b2Fixture * fixture)  {
        py::object f = object_.attr("say_goodbye_fixture");
        f(FixtureHolder(fixture));
    }
    #ifdef PYBOX2D_LIQUID_FUN
    virtual void SayGoodbye(b2ParticleGroup* group){
        py::object f = object_.attr("say_goodbye_particle_group");
        f(ParticleGroupHolder(group));
    }
    virtual void SayGoodbye(b2ParticleSystem* particleSystem, int32 index){
        py::object f = object_.attr("say_goodbye_particle_System");
        f(ParticleSystemHolder(particleSystem), index);
    }
    #endif
private:
    py::object object_;
};

class PyB2ContactFilterCaller : public b2ContactFilter {
public:
    /* Inherit the constructors */
    //using b2ContactFilter::b2ContactFilter;

    virtual ~PyB2ContactFilterCaller() {}

    PyB2ContactFilterCaller(const py::object & object)
    : object_(object){
    }

    virtual bool ShouldCollide(b2Fixture* fixtureA, b2Fixture* fixtureB) {
        py::object f = object_.attr("should_collide_fixture_fixture");
        bool ret = f(FixtureHolder(fixtureA), FixtureHolder(fixtureB)).cast<bool>();
        return ret;
    }
    #ifdef PYBOX2D_LIQUID_FUN
    virtual bool ShouldCollide(b2Fixture* fixtureA, b2ParticleSystem* particleSystem, int32 particleIndex) {
        py::object f = object_.attr("should_collide_fixture_particle");
        bool ret = f(FixtureHolder(fixtureA), ParticleSystemHolder(particleSystem), particleIndex).cast<bool>();
        return ret;
    }

    virtual bool ShouldCollide(b2ParticleSystem* particleSystem, int32 particleIndexA, int32 particleIndexB) {
        py::object f = object_.attr("should_collide_particle_particle");
        bool ret = f(ParticleSystemHolder(particleSystem), particleIndexA, particleIndexB).cast<bool>();
        return ret;
    }
    #endif
private:
    py::object object_;
};

class PyB2ContactListenerCaller : public b2ContactListener{
public:


    virtual ~PyB2ContactListenerCaller() {}
    PyB2ContactListenerCaller(const py::object & object)
    : object_(object){ 

        m_has_begin_contact = py::hasattr(object_, "begin_contact");
        m_has_end_contact = py::hasattr(object_, "end_contact");
        #ifdef PYBOX2D_LIQUID_FUN
        m_has_begin_contact_particle_body  = py::hasattr(object_, "begin_contact_particle_body");
        m_has_end_contact_fixture_particle  = py::hasattr(object_, "end_contact_fixture_particle");
        m_has_begin_contact_particle  = py::hasattr(object_, "begin_contact_particle");
        m_has_end_pontact_particle  = py::hasattr(object_, "end_pontact_particle");
        #endif
        m_has_pre_solve  = py::hasattr(object_, "pre_solve");
        m_has_post_solve  = py::hasattr(object_, "post_solve");
    }


    virtual void BeginContact(b2Contact* contact) { 
        if(m_has_begin_contact)
        {
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("begin_contact");
            f(ContactHolder(contact));
        }
    }

    virtual void EndContact(b2Contact* contact) { 
        if(m_has_end_contact){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("end_contact");
            f(ContactHolder(contact));
        }

    }

    #ifdef PYBOX2D_LIQUID_FUN
    virtual void BeginContact(b2ParticleSystem* particleSystem,
                              b2ParticleBodyContact* particleBodyContact){

        if(m_has_begin_contact_particle_body){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("begin_contact_particle_body");
            f(ParticleSystemHolder(particleSystem), particleBodyContact);
        }
    }

    virtual void EndContact(b2Fixture* fixture,
                            b2ParticleSystem* particleSystem, int32 index){

        if(m_has_end_contact_fixture_particle){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("end_contact_fixture_particle");
            f(FixtureHolder(fixture), ParticleSystemHolder(particleSystem), index);  
        }
    }

    virtual void BeginContact(b2ParticleSystem* particleSystem,
                              b2ParticleContact* particleContact){

        if(m_has_begin_contact_particle){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("begin_contact_particle");
            f(ParticleSystemHolder(particleSystem),  particleContact);  
        }
    }

    virtual void EndContact(b2ParticleSystem* particleSystem,
                            int32 indexA, int32 indexB){
        if(m_has_end_pontact_particle){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("end_pontact_particle");
            f(ParticleSystemHolder(particleSystem),  indexA, indexB);  
        }
    }
    #endif
    virtual void PreSolve(b2Contact* contact, const b2Manifold* oldManifold){
        if(m_has_pre_solve){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("pre_solve");
            f(ContactHolder(contact),  ManifoldHolder(oldManifold)); 
        }
    }

    virtual void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse){
        if(m_has_post_solve){
            py::gil_scoped_acquire acquire;
            py::object f = object_.attr("post_solve");
            f(ContactHolder(contact),  ContactImpulseHolder(impulse));  
        }
    }
private:
    py::object object_;

    bool m_has_begin_contact;
    bool m_has_end_contact;
    #ifdef PYBOX2D_LIQUID_FUN
    bool m_has_begin_contact_particle_body;
    bool m_has_end_contact_fixture_particle;
    bool m_has_begin_contact_particle;
    bool m_has_end_pontact_particle;
    #endif
    bool m_has_pre_solve;
    bool m_has_post_solve;
};

class PyB2QueryCallbackCaller : public b2QueryCallback{
public:


    virtual ~PyB2QueryCallbackCaller() {}
    PyB2QueryCallbackCaller(const py::object & object)
    : object_(object){
    }

    virtual bool ReportFixture(b2Fixture* fixture){
        py::object f = object_.attr("report_fixture");
        bool ret = f(fixture).cast<bool>();;
        return ret;
    }

    #ifdef PYBOX2D_LIQUID_FUN
    /// Called for each particle found in the query AABB.
    /// @return false to terminate the query.
    virtual bool ReportParticle(const b2ParticleSystem* particleSystem,
                                int32 index)
    {
        py::gil_scoped_acquire acquire;
        py::object f = object_.attr("report_particle");
        bool ret = f(particleSystem, index).cast<bool>();;
        return ret;
    }

    /// Cull an entire particle system from b2World::QueryAABB. Ignored for
    /// b2ParticleSystem::QueryAABB.
    /// @return true if you want to include particleSystem in the AABB query,
    /// or false to cull particleSystem from the AABB query.
    virtual bool ShouldQueryParticleSystem(
        const b2ParticleSystem* particleSystem)
    {
        py::gil_scoped_acquire acquire;
        py::object f = object_.attr("should_query_particle_system");
        bool ret = f(particleSystem).cast<bool>();;
        return ret;
    }

    #endif
private:
    py::object object_;
};

class PyB2RayCastCallbackCaller : public b2RayCastCallback
{
public:
    virtual ~PyB2RayCastCallbackCaller() {}
    PyB2RayCastCallbackCaller(const py::object & object)
    : object_(object){
    }
    /// Called for each fixture found in the query. You control how the ray cast
    /// proceeds by returning a float:
    /// return -1: ignore this fixture and continue
    /// return 0: terminate the  cast
    /// return fraction: clip the ray to this point
    /// return 1: don't clip the ray and continue
    /// @param fixture the fixture hit by the ray
    /// @param point the point of initial intersection
    /// @param normal the normal vector at the point of intersection
    /// @return -1 to filter, 0 to terminate, fraction to clip the ray for
    /// closest hit, 1 to continue
    virtual float ReportFixture(  b2Fixture* fixture, const b2Vec2& point,
                                    const b2Vec2& normal, float fraction){
        py::gil_scoped_acquire acquire;
        py::object f = object_.attr("report_fixture");
        float ret = f(fixture, point, normal, fraction).cast<float>();
        return ret;
    }


    #ifdef PYBOX2D_LIQUID_FUN

    /// cast proceeds by returning a float:
    /// return <=0: ignore the remaining particles in this particle system
    /// return fraction: ignore particles that are 'fraction' percent farther
    ///   along the line from 'point1' to 'point2'. Note that 'point1' and
    ///   'point2' are parameters to b2World::RayCast.
    /// @param particleSystem the particle system containing the particle
    /// @param index the index of the particle in particleSystem
    /// @param point the point of intersection bt the ray and the particle
    /// @param normal the normal vector at the point of intersection
    /// @param fraction percent (0.0~1.0) from 'point0' to 'point1' along the
    ///   ray. Note that 'point1' and 'point2' are parameters to
    ///   b2World::RayCast.
    /// @return <=0 to ignore rest of particle system, fraction to ignore
    /// particles that are farther away.
    virtual float ReportParticle(const b2ParticleSystem* particleSystem,
                                   int32 index, const b2Vec2& point,
                                   const b2Vec2& normal, float fraction)
    {
        py::gil_scoped_acquire acquire;
        B2_NOT_USED(particleSystem);
        B2_NOT_USED(index);
        B2_NOT_USED(&point);
        B2_NOT_USED(&normal);
        B2_NOT_USED(fraction);
        return 0;
    }

    /// Cull an entire particle system from b2World::RayCast. Ignored in
    /// b2ParticleSystem::RayCast.
    /// @return true if you want to include particleSystem in the RayCast, or
    /// false to cull particleSystem from the RayCast.
    virtual bool ShouldQueryParticleSystem(
        const b2ParticleSystem* particleSystem)
    {
        py::gil_scoped_acquire acquire;
        B2_NOT_USED(particleSystem);
        return true;
    }
    #endif

private:
    py::object object_;
};
