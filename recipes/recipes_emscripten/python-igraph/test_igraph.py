import igraph

g = igraph.Graph.Famous("Petersen")
assert g.vcount() == 10
assert g.ecount() == 15
print("python-igraph OK")
