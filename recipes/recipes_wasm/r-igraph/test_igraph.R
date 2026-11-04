library(igraph)

test_1 <- function() {
    g <- make_empty_graph()
    print(g)
    stopifnot(inherits(g, "igraph"), vcount(g) == 0L)
}

test_2 <- function() {
    g <- make_graph(edges = c(1, 2, 1, 5), n = 10, directed = FALSE)
    print(g)
    stopifnot(inherits(g, "igraph"), vcount(g) == 10L, ecount(g) == 2L)
}

test_3 <- function() {
    g <- make_graph(~ 1--2, 1--5, 3, 4, 5, 6, 7, 8, 9, 10)
    g <- add_vertices(g, 27)
    g <- add_edges(g, edges = c(1, 35, 1, 36, 34, 37))
    print(g)
    stopifnot(inherits(g, "igraph"), vcount(g) == 37L)
}

test_4 <- function() {
    g <- make_graph("Zachary")
    print(g)
    stopifnot(inherits(g, "igraph"), vcount(g) > 0L, ecount(g) > 0L)
}

for (name in ls(pattern = "^test_[0-9]+$")) {
  cat("Running ", name, "\n", sep = "")
  get(name)()
}
