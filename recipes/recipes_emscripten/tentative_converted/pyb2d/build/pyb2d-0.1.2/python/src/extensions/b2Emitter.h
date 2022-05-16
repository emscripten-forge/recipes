#include <random>
#include "../box2d_wrapper.hpp"



struct b2EmitterDefBase
{
    b2EmitterDefBase();

    b2Body * body;
    b2Transform transform;
    float  emitRate;
    float lifetime;
    int seed;
};


struct b2RadialEmitterDef : public b2EmitterDefBase
{
    b2RadialEmitterDef();

    float innerRadius;
    float outerRadius;
    float velocityMagnitude;

    float startAngle;
    float stopAngle;
};


struct b2LinearEmitterDef : public b2EmitterDefBase
{
    b2LinearEmitterDef();
 
    b2Vec2 size;
    b2Vec2 velocity;
};


class b2EmitterBase
{
public:
    b2EmitterBase(
        b2ParticleSystem * particleSystem, 
        const b2EmitterDefBase & def
    );
    void CreateParticle(b2ParticleDef  def);
    b2Body* GetBody()const;
    void SetBody(b2Body * body);

    const b2Transform & GetTransform()const;
    void SetTransform(const b2Transform & transform);

    const b2Vec2 & GetPosition()const;
    void SetPosition(const b2Vec2 & vec);

    float32 GetAngle()const;
    void SetAngle(const float32 angle);

private:


    b2ParticleSystem * m_particleSystem;

    b2Body * m_body;
    b2Transform m_transform;
    float  m_emitRate;
    float m_lifetime;
    int m_seed;
};

class b2LinearEmitter: public b2EmitterBase {
public:
    b2LinearEmitter( 
        b2ParticleSystem * particleSystem, 
        const b2LinearEmitterDef & def
    );

    int Step(const float dt);

private:
    b2LinearEmitterDef m_emmiter_def;
    float m_remainder;
    std::uniform_real_distribution<float> m_uniform01;
    std::mt19937 m_gen;
};


class b2RadialEmitter : b2EmitterBase
{
public:
    b2RadialEmitter( 
        b2ParticleSystem * particleSystem, 
        const b2RadialEmitterDef & def
    );

    int Step(const float dt);

private:
    b2RadialEmitterDef m_emmiter_def;

    float m_remainder;
    std::uniform_real_distribution<float> m_uniform_r;
    std::uniform_real_distribution<float> m_uniform_angle;
    std::mt19937 m_gen;
};


