library(igraph)

g <- make_empty_graph()
g <- make_graph(edges = c(1, 2, 1, 5), n = 10, directed = FALSE)
g <- make_graph(~ 1--2, 1--5, 3, 4, 5, 6, 7, 8, 9, 10)
g <- add_vertices(g, 27)
g <- add_edges(g, edges = c(1, 35, 1, 36, 34, 37))
print(g)

g <- make_graph("Zachary")
print(g)