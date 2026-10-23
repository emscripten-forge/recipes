library(matrixStats)

m <- matrix(1:9, nrow = 3)
stopifnot(identical(rowSums2(m), rowSums(m)))
print(colMeans2(m))
