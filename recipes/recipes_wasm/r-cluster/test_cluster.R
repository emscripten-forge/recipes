library(cluster)

cl <- pam(iris[, 1:4], k = 3)
stopifnot(length(unique(cl$clustering)) == 3)
