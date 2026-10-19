library(yardstick)
library(dplyr)

test_1 <- function() {
    stopifnot(is.function(rmse), is.function(accuracy), is.function(roc_auc))
    print(head(sort(getNamespaceExports("yardstick")), 10))
}

test_2 <- function() {
    set.seed(1)
    truth <- rnorm(20)
    estimate <- truth + rnorm(20, sd = 0.5)
    df <- data.frame(truth = truth, estimate = estimate)
    result <- rmse(df, truth, estimate)
    print(result)
    stopifnot(nrow(result) == 1, result$.estimate > 0)
}

test_3 <- function() {
    set.seed(1)
    truth <- factor(sample(c("a", "b"), 30, replace = TRUE))
    estimate <- truth
    estimate[1:5] <- if (estimate[1] == "a") "b" else "a"
    df <- data.frame(truth = truth, estimate = estimate)
    result <- accuracy(df, truth, estimate)
    print(result)
    stopifnot(result$.estimate > 0.5, result$.estimate <= 1)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
