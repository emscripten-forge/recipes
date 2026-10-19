print('Loading vctrs package')
library(vctrs)
print('... vctrs package loaded successfully')

test_1 <- function() {
    stopifnot(identical(vec_size(1:10), 10L))
    stopifnot(identical(vec_size(data.frame(x = 1:3)), 3L))
}

test_2 <- function() {
    stopifnot(identical(vec_ptype_common(integer(), double()), numeric()))
    stopifnot(identical(vec_c(1L, 2.5), c(1, 2.5)))
}

test_3 <- function() {
    x <- 1:5
    stopifnot(identical(vec_slice(x, 2:4), 2:4))
    stopifnot(identical(vec_rep(1L, 3), c(1L, 1L, 1L)))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
