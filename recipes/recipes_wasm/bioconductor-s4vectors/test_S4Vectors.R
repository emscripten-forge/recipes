library(S4Vectors)

test_1 <- function() {
    x <- Rle(c(1L, 1L, 2L, 2L, 2L, 3L))
    print(x)
    stopifnot(inherits(x, "Rle"), length(x) == 6L)
}

test_2 <- function() {
    df <- DataFrame(a = 1:3, b = letters[1:3])
    print(df)
    stopifnot(inherits(df, "DataFrame"), nrow(df) == 3L, ncol(df) == 2L)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
