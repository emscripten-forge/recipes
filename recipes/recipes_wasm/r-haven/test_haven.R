library(haven)

test_1 <- function() {
    x <- labelled(c(1, 2, 1), labels = c(Yes = 1, No = 2))
    print(x)
    stopifnot(is.labelled(x), as_factor(x)[1] == "Yes")
}

test_2 <- function() {
    x <- labelled(c(1, 2, NA), labels = c(Yes = 1, No = 2))
    y <- zap_labels(x)
    print(y)
    stopifnot(is.numeric(y), !is.labelled(y), identical(as.numeric(y), c(1, 2, NA)))
}

test_3 <- function() {
    x <- labelled_spss(c(1, 2, 9), labels = c(Yes = 1, No = 2), na_values = 9)
    print(x)
    stopifnot(inherits(x, "haven_labelled_spss"), is.na(x[3]))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
