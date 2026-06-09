library(proxy)

s <- simil(iris[, 1:4], method = "cosine")
stopifnot(length(s) == choose(nrow(iris), 2))
