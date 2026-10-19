library(tidyr)
library(dplyr)

test_1 <- function() {
    df <- tibble(id = 1:2, x = c(1, 3), y = c(10, 20))
    long <- pivot_longer(df, cols = c(x, y), names_to = "name", values_to = "value")
    print(long)
    stopifnot(nrow(long) == 4, all(c("name", "value") %in% names(long)))
}

test_2 <- function() {
    df <- tibble(id = c(1, 1, 2, 2), name = c("x", "y", "x", "y"), value = 1:4)
    wide <- pivot_wider(df, names_from = name, values_from = value)
    print(wide)
    stopifnot(nrow(wide) == 2, all(c("x", "y") %in% names(wide)))
}

test_3 <- function() {
    df <- tibble(x = c(1, NA, 3), y = c(2, NA, 3))
    filled <- fill(df, x, y)
    print(filled)
    stopifnot(!any(is.na(filled$x)), !any(is.na(filled$y)))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
