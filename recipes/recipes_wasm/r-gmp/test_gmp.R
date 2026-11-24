library(gmp)

test_1 <- function() {
    print(gmpVersion())
}

test_2 <- function() {
    a <- as.bigz(23)
    b <- as.bigz(45)
    stopifnot(identical(as.character(a + b), "68"))
    stopifnot(identical(as.character(a * b), "1035"))
    stopifnot(identical(as.character(b %/% a), "1"))
    stopifnot(identical(as.character(b %% a), "22"))
}

test_3 <- function() {
    q <- as.bigq(32, 7)
    stopifnot(identical(as.character(q), "32/7"))
    stopifnot(identical(as.character(q + as.bigq(1, 7)), "33/7"))
}

test_4 <- function() {
    stopifnot(identical(as.character(factorialZ(10)), "3628800"))
    stopifnot(identical(as.character(chooseZ(10, 3)), "120"))
    stopifnot(isprime(17) > 0)
    stopifnot(as.integer(nextprime(14)) == 17)
}

test_5 <- function() {
    x <- matrix(1:6, 3)
    z <- as.bigz(x)
    stopifnot(identical(dim(z), dim(x)))
    stopifnot(identical(as.character(z %*% t(z)), as.character(as.bigz(x %*% t(x)))))
}

cat("Running test_1\n")
test_1()

cat("Running test_2\n")
test_2()

cat("Running test_3\n")
test_3()

cat("Running test_4\n")
test_4()

cat("Running test_5\n")
test_5()
