print('Loading purrr package')
library(purrr)
print('... purrr package loaded successfully')

test_1 <- function() {
    x <- map_dbl(1:5, ~ .x * 2)
    stopifnot(identical(x, c(2, 4, 6, 8, 10)))
    print(x)
}

test_2 <- function() {
    x <- keep(1:10, ~ .x %% 2 == 0)
    stopifnot(identical(x, c(2L, 4L, 6L, 8L, 10L)))
    print(x)
}

test_3 <- function() {
    x <- reduce(1:5, `+`)
    stopifnot(identical(x, 15L))
    print(x)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
