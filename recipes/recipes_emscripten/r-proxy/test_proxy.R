library(proxy)

d <- dist(iris[, 1:4], method = "euclidean")
stopifnot(length(d) == choose(nrow(iris), 2))
