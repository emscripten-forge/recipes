library(sparsevctrs)

test_1 <- function() {
    x <- sparse_double(values = c(1, 5, 3), positions = c(1L, 5L, 8L), length = 10L)
    stopifnot(length(x) == 10L)
    print(x)
}

test_2 <- function() {
    x <- sparse_integer(values = c(2L, 4L), positions = c(2L, 4L), length = 5L)
    stopifnot(identical(as.integer(x), c(0L, 2L, 0L, 4L, 0L)))
    print(x)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
