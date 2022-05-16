
from . _b2d import b2AABB
from . extend_math import vec2


Aabb = b2AABB


def aabb(lower_bound=None, upper_bound=None, p=None, r=None):
    if  lower_bound is not None and upper_bound is not None:

        lb = vec2(lower_bound)
        ub = vec2(upper_bound)
    elif r is not None and p is not None:
        p = vec2(p)
        rr = vec2(r,r)
        lb = p - rr
        ub = p + rr

    r = b2AABB()
    r.lower_bound = lb
    r.upper_bound = ub

    return r
