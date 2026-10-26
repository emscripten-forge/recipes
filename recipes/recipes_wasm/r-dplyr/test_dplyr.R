library(dplyr)

test_1 <- function() {
    x <- mtcars |>
        filter(cyl == 4) |>
        summarise(mean_mpg = mean(mpg))
    stopifnot(nrow(x) == 1L, is.finite(x$mean_mpg))
    print(x)
}

test_2 <- function() {
    x <- mtcars |>
        group_by(cyl) |>
        summarise(n = n(), .groups = "drop")
    stopifnot(nrow(x) == 3L)
    print(x)
}

test_3 <- function() {
    x <- mtcars |> mutate(kpl = mpg * 0.425144)
    stopifnot("kpl" %in% names(x), nrow(x) == nrow(mtcars))
    print(head(x))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
