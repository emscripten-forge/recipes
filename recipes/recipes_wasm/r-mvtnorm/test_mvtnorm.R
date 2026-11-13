library(mvtnorm)

test_1 <- function() {
    p <- 3
    x <- rep(0, p)
    dens <- dmvnorm(x, mean = rep(0, p), sigma = diag(p), log = FALSE, checkSymmetry = TRUE)
    print(dens)
    stopifnot(is.numeric(dens), length(dens) == 1)
}

test_2 <- function() {
    p <- 3
    n <- 5
    samples <- rmvnorm(
        n,
        mean = rep(0, p),
        sigma = diag(p),
        method = "chol",
        checkSymmetry = TRUE
    )
    print(samples)
    stopifnot(is.matrix(samples), nrow(samples) == n, ncol(samples) == p)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
