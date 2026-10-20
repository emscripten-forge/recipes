library(flashClust)

d <- dist(iris[, 1:4])
h <- flashClust(d, method = "ward")
stopifnot(inherits(h, "hclust"))
