library(glmnet)

test_1 <- function() {
    set.seed(1)
    x <- matrix(rnorm(50 * 10), 50, 10)
    y <- rnorm(50)
    fit <- glmnet(x, y)
    print(fit)
    stopifnot(length(fit$lambda) > 0)
}

print("Running test_1")
test_1()
