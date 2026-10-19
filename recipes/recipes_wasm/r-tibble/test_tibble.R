library(tibble)

test_1 <- function() {
    x <- tibble(a = 1:3, b = letters[1:3])
    stopifnot(inherits(x, "tbl_df"), nrow(x) == 3L)
    print(x)
}

test_2 <- function() {
    x <- as_tibble(mtcars)
    stopifnot(inherits(x, "tbl_df"), nrow(x) == nrow(mtcars))
    print(head(x))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
