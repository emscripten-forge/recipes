from ligo.segments import segment, segmentlist

a = segment(1, 2)
b = segment(2, 3)
c = segment(5, 6)

assert a.connects(b)
assert a in (segmentlist([a]) + segmentlist([b]))
assert (segmentlist([a]) + segmentlist([b])).intersects(b)
assert a.disjoint(c)
