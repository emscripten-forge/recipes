library(readr)

test_1 <- function() {
    csv <- "a,b\n1,2\n3,4\n"
    df <- read_csv(I(csv), show_col_types = FALSE)
    print(df)
    stopifnot(nrow(df) == 2, ncol(df) == 2, all(df$a == c(1, 3)))
}

test_2 <- function() {
    tsv <- "x\ty\n10\t20\n"
    df <- read_tsv(I(tsv), show_col_types = FALSE)
    print(df)
    stopifnot(df$x == 10, df$y == 20)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
