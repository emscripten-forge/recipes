library(xts)

test_1 <- function() {
    x <- xts(1:5, order.by = as.Date("2020-01-01") + 0:4)
    stopifnot(inherits(x, "xts"), nrow(x) == 5L)
    print(x)
}

test_2 <- function() {
    x <- xts(1:5, order.by = as.Date("2020-01-01") + 0:4)
    y <- to.period(x, period = "days")
    stopifnot(inherits(y, "xts"))
    print(y)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
