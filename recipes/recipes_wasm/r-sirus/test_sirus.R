library(sirus)

test_1 <- function() {
    stopifnot(is.function(sirus.fit))
    print(head(sort(getNamespaceExports("sirus")), 10))
}

test_2 <- function() {
    set.seed(1)
    n <- 100
    p <- 5
    X <- as.data.frame(matrix(rnorm(n * p), n, p))
    y <- as.numeric(X[, 1] + X[, 2] > 0)
    fit <- sirus.fit(X, y, num.rule.max = 5, num.threads = 1, verbose = FALSE)
    print(fit$rules)
    stopifnot(!is.null(fit$rules))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
