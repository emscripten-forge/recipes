library(Rtsne)

set.seed(42)
X <- matrix(rnorm(50 * 5), 50, 5)
result <- Rtsne(X, dims = 2, perplexity = 5, verbose = FALSE)
stopifnot(nrow(result$Y) == 50, ncol(result$Y) == 2)
