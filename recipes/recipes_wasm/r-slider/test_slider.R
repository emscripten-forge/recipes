library(slider)

test_1 <- function() {
    x <- slide_dbl(1:5, mean, .before = 1, .after = 1)
    stopifnot(length(x) == 5L, all(is.finite(x)))
    print(x)
}

test_2 <- function() {
    x <- slide_sum(1:5, before = 2)
    stopifnot(all.equal(x, c(1, 3, 6, 9, 12)))
    print(x)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
