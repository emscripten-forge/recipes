library(arrow)

test_1 <- function() {
    a <- Array$create(1:5)
    print(a)
    stopifnot(inherits(a, "Array"), a$length() == 5L)
}

test_2 <- function() {
    tbl <- arrow_table(x = 1:3, y = c("a", "b", "c"))
    print(tbl)
    stopifnot(inherits(tbl, "Table"), tbl$num_rows == 3L, tbl$num_columns == 2L)
}

test_3 <- function() {
    df <- as.data.frame(arrow_table(x = 1:4, y = letters[1:4]))
    print(df)
    stopifnot(is.data.frame(df), nrow(df) == 4L, ncol(df) == 2L)
}

for (name in ls(pattern = "^test_[0-9]+$")) {
  cat("Running ", name, "\n", sep = "")
  get(name)()
}
