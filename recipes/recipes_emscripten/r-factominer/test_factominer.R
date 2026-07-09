library(FactoMineR)

pca <- PCA(iris[, 1:4], graph = FALSE)
stopifnot(ncol(pca$ind$coord) == 4)
