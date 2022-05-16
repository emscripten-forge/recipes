from ._b2d import *
from .tools import _classExtender
from . extend_math import vec2

class ParticleGroupFlag(object):
    # prevents overlapping or leaking.
    solidParticleGroup = 1 << 0
    # Keeps its shape.
    rigidParticleGroup = 1 << 1
    # Won't be destroyed if it gets empty.
    particleGroupCanBeEmpty = 1 << 2
    # Will be destroyed on next simulation step.
    particleGroupWillBeDestroyed = 1 << 3
    # Updates depth data on next simulation step.
    particleGroupNeedsUpdateDepth = 1 << 4
    particleGroupInternalMask = particleGroupWillBeDestroyed | particleGroupNeedsUpdateDepth

class ParticleFlag(object):
    waterParticle = 0
    # Removed after next simulation step.
    zombieParticle = 1 << 1
    # Zero velocity.
    wallParticle = 1 << 2
    # With restitution from stretching.
    springParticle = 1 << 3
    # With restitution from deformation.
    elasticParticle = 1 << 4
    # With viscosity.
    viscousParticle = 1 << 5
    # Without isotropic pressure.
    powderParticle = 1 << 6
    # With surface tension.
    tensileParticle = 1 << 7
    # Mix color between contacting particles.
    colorMixingParticle = 1 << 8
    # Call b2DestructionListener on destruction.
    destructionListenerParticle = 1 << 9
    # Prevents other particles from leaking.
    barrierParticle = 1 << 10
    # Less compressibility.
    staticPressureParticle = 1 << 11
    # Makes pairs or triads with other particles.
    reactiveParticle = 1 << 12
    # With high repulsive force.
    repulsiveParticle = 1 << 13
    # Call b2ContactListener when this particle is about to interact with
    # a rigid body or stops interacting with a rigid body.
    # This results in an expensive operation compared to using
    # fixtureContactFilterParticle to detect collisions between
    # particles.
    fixtureContactListenerParticle = 1 << 14
    # Call b2ContactListener when this particle is about to interact with
    # another particle or stops interacting with another particle.
    # This results in an expensive operation compared to using
    # particleContactFilterParticle to detect collisions between
    # particles.
    particleContactListenerParticle = 1 << 15
    # Call b2ContactFilter when this particle interacts with rigid bodies.
    fixtureContactFilterParticle = 1 << 16
    # Call b2ContactFilter when this particle interacts with other
    # particles.
    particleContactFilterParticle = 1 << 17

def particle_system_def(
    strict_contact_check = None,
    density = None,
    gravity_scale = None,
    radius = None,
    max_count = None,
    pressure_strength = None,
    damping_strength = None,
    elastic_strength = None,
    spring_strength = None,
    viscous_strength = None,
    surface_tension_pressure_strength = None,
    surface_tension_normal_strength = None,
    repulsive_strength = None,
    powder_strength = None,
    ejection_strength = None,
    static_pressure_strength = None,
    static_pressure_relaxation = None,
    static_pressure_iterations = None,
    color_mixing_strength = None,
    destroy_by_age = None,
    lifetime_granularity = None,
):
    d = ParticleSystemDef()

    if strict_contact_check  is not None:
        d.strict_contact_check = strict_contact_check
    if density  is not None:
        d.density = density
    if gravity_scale  is not None:
        d.gravity_scale = gravity_scale
    if radius  is not None:
        d.radius = radius
    if max_count  is not None:
        d.max_count = max_count
    if pressure_strength  is not None:
        d.pressure_strength = pressure_strength
    if damping_strength  is not None:
        d.damping_strength = damping_strength
    if elastic_strength  is not None:
        d.elastic_strength = elastic_strength
    if spring_strength  is not None:
        d.spring_strength = spring_strength
    if viscous_strength  is not None:
        d.viscous_strength = viscous_strength
    if surface_tension_pressure_strength  is not None:
        d.surface_tension_pressure_strength = surface_tension_pressure_strength
    if surface_tension_normal_strength  is not None:
        d.surface_tension_normal_strength = surface_tension_normal_strength
    if repulsive_strength  is not None:
        d.repulsive_strength = repulsive_strength
    if powder_strength  is not None:
        d.powder_strength = powder_strength
    if ejection_strength  is not None:
        d.ejection_strength = ejection_strength
    if static_pressure_strength  is not None:
        d.static_pressure_strength = static_pressure_strength
    if static_pressure_relaxation  is not None:
        d.static_pressure_relaxation = static_pressure_relaxation
    if static_pressure_iterations  is not None:
        d.static_pressure_iterations = static_pressure_iterations
    if color_mixing_strength  is not None:
        d.color_mixing_strength = color_mixing_strength
    if destroy_by_age  is not None:
        d.destroy_by_age = destroy_by_age
    if lifetime_granularity  is not None:
        d.lifetime_granularity = lifetime_granularity

    return d


def particle_group_def(
    flags=None,
    group_flags=None,
    position=None,
    angle=None,
    linear_velocity=None,
    angular_velocity=None,
    color=None,
    strength=None,
    shape=None,
    stride=None,
    particle_count=None,
    lifetime=None,
    group=None
):
    d = ParticleGroupDef()
    if flags is not None:
        d.flags = flags
    if group_flags is not None:
        d.group_flags = group_flags
    if position is not None:
        d.position = position
    if angle is not None:
        d.angle = angle
    if linear_velocity is not None:
        d.linear_velocity = linear_velocity
    if angular_velocity is not None:
        d.angular_velocity = angular_velocity
    if color is not None:
        d.color = color
    if color is not None:
        d.color = color
    if strength is not None:
        d.strength = strength
    if shape is not None:
        d.shape = shape
    if stride is not None:
        d.stride = stride
    if particle_count is not None:
        d.particle_count = particle_count
    if lifetime is not None:
        d.lifetime = lifetime
    if group is not None:
        d.group(shape)
    
    return d


def particle_def(
    flags = None,
    position = None,
    velocity = None,
    color = None,
    lifetime = None,
    group = None
):
    pd = ParticleDef() 

    if flags is not None:
        pd.flags = flags
    if position is not None:
        pd.position = vec2(position)
    if velocity is not None:
        pd.velocity = vec2(velocity)
    if color is not None:
        pd.color = color
    if lifetime is not None:
        pd.lifetime = lifetime
    if group is not None:
        pd.group = group

    return pd
#class _ParticleSystem(b2ParticleSystem):
#    pass
#_classExtender(_ParticleSystem,['group','shape'])


class _ParticleGroupDef(ParticleGroupDef):

    @property
    def group(self):
        return self._group()
    @group.setter
    def group(self, group):
        self._setGroup(shape)


    @property
    def shape(self):
        return self._shape()
    @shape.setter
    def shape(self, shape):
        self._setShape(shape)

_classExtender(_ParticleGroupDef,['group','shape'])


