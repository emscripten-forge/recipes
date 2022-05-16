from . _b2d import DrawCaller, BatchDebugDrawCaller
from . tools import _classExtender, GenericB2dIter
from contextlib import contextmanager


import numbers 

class DrawFlags(object):
    shape_bit              = 0x0001
    joint_bit              = 0x0002
    aabb_bit               = 0x0004
    pair_bit               = 0x0008
    center_of_mass_bit     = 0x0010
    particle_bit           = 0x0020

draw_flags_dict = {
    "shape"              : 0x0001,
    "joint"              : 0x0002,
    "aabb"               : 0x0004,
    "pair"               : 0x0008,
    "center_of_mass"     : 0x0010,
    "particle"           : 0x0020
}



def _extendDrawCaller():
    
    def append_flags(self, flag_list_or_int):
        if isinstance(flag_list_or_int, numbers.Number):
            self._append_flags_int(flag_list_or_int)
        else:
            flag_list = flag_list_or_int
            if isinstance(flag_list, str):
                flag_list = [flag_list]
            for flag in flag_list:
                self._append_flags_int(draw_flags_dict[flag])
    DrawCaller.append_flags =append_flags
    BatchDebugDrawCaller.append_flags =append_flags

    def clear_flags(self, flag_list_or_int):
        if isinstance(flag_list_or_int, numbers.Number):
            self._clear_flags_int(flag_list_or_int)
        else:
            flag_list = flag_list_or_int
            if isinstance(flag_list, str):
                flag_list = [flag_list]
            for flag in flag_list:
                self._clear_flags_int(draw_flags_dict[flag])

    DrawCaller.clear_flags = clear_flags
    BatchDebugDrawCaller.clear_flags =clear_flags
_extendDrawCaller()
del _extendDrawCaller

