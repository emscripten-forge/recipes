#include <random>
#include "b2Emitter.h"


#ifndef M_PI
    #define M_PI 3.14159265358979323846
#endif



b2EmitterDefBase::b2EmitterDefBase()
:
    body(nullptr),
    transform(),
    emitRate(1),
    lifetime(0.0f),
    seed(42)
{

}

b2RadialEmitterDef::b2RadialEmitterDef()
:   b2EmitterDefBase(),
    innerRadius(0.0f),
    outerRadius(1.0f),
    velocityMagnitude(0),
    startAngle(0),
    stopAngle(2.0f * M_PI)
{

}
 



b2LinearEmitterDef::b2LinearEmitterDef()
:   b2EmitterDefBase(),
    size(1,1),
    velocity(0,0)
{

}




b2EmitterBase::b2EmitterBase(
    b2ParticleSystem * particleSystem, 
    const b2EmitterDefBase & def
)
:   m_particleSystem(particleSystem),
    m_body(def.body),
    m_transform(def.transform),
    m_lifetime(def.lifetime),
    m_seed(def.seed)
{

}

void b2EmitterBase::CreateParticle(b2ParticleDef  def)
{
    def.lifetime = m_lifetime;
    //def.emitRate = m_emitRate;

    m_particleSystem->CreateParticle(def);

    if(m_body != nullptr)
    {
        //std::cout<<"ApplyLinearImpulse "<<std::endl;
        const auto & pos = def.position;
        const auto & velocity = def.velocity;
        const auto density = m_particleSystem->GetDensity();
        const auto radius = m_particleSystem->GetRadius();
        const auto area = radius*radius * M_PI;
        const auto m = area * density;
        m_body->ApplyLinearImpulse(m*velocity * -1.0f, pos, true);
    }
}



b2Body* b2EmitterBase::GetBody()const
{    
    return m_body;
}
void b2EmitterBase::SetBody(b2Body * body){
    m_body=body;
}

const b2Transform & b2EmitterBase::GetTransform()const
{
    return m_transform;
}
void b2EmitterBase::SetTransform(const b2Transform & transform)
{
    m_transform=transform;
}

const b2Vec2 & b2EmitterBase::GetPosition()const
{
    return m_transform.p;
}

void b2EmitterBase::SetPosition(const b2Vec2 & vec)
{
    m_transform.p=vec;
}

float32 b2EmitterBase::GetAngle()const
{
    return m_transform.q.GetAngle();
}

void b2EmitterBase::SetAngle(const float32 angle)
{
    m_transform.Set(this->GetPosition(), angle);
}





b2LinearEmitter::b2LinearEmitter( 
    b2ParticleSystem * particleSystem, 
    const b2LinearEmitterDef & def
)
:   b2EmitterBase(particleSystem, def),
    m_emmiter_def(def),
    m_remainder(0.0),
    m_uniform01(0.0f,1.0f),
    m_gen()
{

}

int b2LinearEmitter::Step(const float dt){
    const auto & edef = m_emmiter_def;


    const auto & center = this->GetPosition();
    const auto & angle = this->GetAngle();
    const auto & size = edef.size;

    m_remainder += dt * edef.emitRate;
    const float dtPerParticle = dt / std::floor(m_remainder);

    int num_created = 0;
    while(m_remainder >= 1.0)
    {   
        const float dtp = dtPerParticle * num_created;

        // get random pos in UNROTATED box
        b2Vec2 pBox;
        pBox.x = size.x * (m_uniform01(m_gen) - 0.5f);
        pBox.y = size.y * (m_uniform01(m_gen) - 0.5f);

        // rotate
        b2Vec2 ppos = b2Mul(b2Rot(angle), pBox) + center;


        // create

        // velocity in body coordinates 
        // => rotate to world
        auto v = edef.velocity;
        b2Vec2 worldVelocity = b2Mul(b2Rot(angle), v);

        // move 
        ppos += worldVelocity * dtp;



        b2ParticleDef pdef;
        pdef.velocity = worldVelocity;
        pdef.position = ppos;
        this->CreateParticle(pdef);

        m_remainder -= 1.0;
        ++num_created;   
    }
    return num_created;
}   



b2RadialEmitter::b2RadialEmitter( 
    b2ParticleSystem * particleSystem, 
    const b2RadialEmitterDef & def
)
:   b2EmitterBase(particleSystem, def),
    m_emmiter_def(def),
    m_remainder(0.0),
    m_uniform_r(
        std::pow(std::min(def.innerRadius, def.innerRadius), 2),
        std::pow(std::max(def.innerRadius, def.outerRadius), 2)
    ),
    m_uniform_angle(def.startAngle, def.stopAngle),
    m_gen()
{

}

int b2RadialEmitter::Step(const float dt)
{
    const auto & edef = m_emmiter_def;

    const auto & position = edef.transform.p;
    auto innerRadius = edef.innerRadius;
    auto outerRadius = edef.outerRadius;

    innerRadius = std::min(innerRadius, innerRadius);
    outerRadius = std::max(innerRadius, outerRadius);

    m_remainder += dt * edef.emitRate;
    const float dtPerParticle = dt / std::floor(m_remainder);

    int num_created = 0;
    while(m_remainder >= 1.0)
    {   
        const float dtp = dtPerParticle * num_created;



        // get random pos in circle
        auto phi = m_uniform_angle(m_gen);
        auto rho = std::sqrt(m_uniform_r(m_gen));

        b2Vec2 circlePos(
            std::sqrt(rho) * std::cos(phi),
            std::sqrt(rho) * std::sin(phi)
        );

        b2Vec2 ppos = circlePos + position;
        
        // velocity
        b2Vec2 unitCirclePos = circlePos / outerRadius;
        b2Vec2 velocity = unitCirclePos * edef.velocityMagnitude;


        // move 
        ppos += velocity * dtp;

        // create
        b2ParticleDef pdef;
        pdef.velocity = velocity;
        pdef.position = ppos;
        pdef.lifetime = edef.lifetime;

        this->CreateParticle(pdef);
        //m_particleSystem->CreateParticle(pdef);

        m_remainder -= 1.0;
        ++num_created;   
    }
    return num_created;
}   

