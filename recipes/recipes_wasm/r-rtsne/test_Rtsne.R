print('Loading Rtsne package')
library(Rtsne)
print('... Rtsne package loaded successfully')

test_1 <- function() {
    set.seed(42)
    X <- matrix(rnorm(50 * 5), 50, 5)
    result <- Rtsne(X, dims = 2, perplexity = 5, verbose = FALSE)
    stopifnot(nrow(result$Y) == 50L)
    stopifnot(ncol(result$Y) == 2L)
}

test_2 <- function() {
    set.seed(1)
    X <- matrix(rnorm(40 * 3), 40, 3)
    result <- Rtsne(X, dims = 2, perplexity = 5, theta = 0.0, verbose = FALSE)
    stopifnot(is.matrix(result$Y))
    stopifnot(all(is.finite(result$Y)))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
