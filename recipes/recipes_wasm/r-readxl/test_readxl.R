library(readxl)

test_1 <- function() {
    path <- readxl_example("datasets.xlsx")
    sheets <- excel_sheets(path)
    print(sheets)
    stopifnot(length(sheets) >= 1)
}

test_2 <- function() {
    path <- readxl_example("datasets.xlsx")
    df <- read_excel(path, sheet = 1)
    print(head(df))
    stopifnot(nrow(df) > 0, ncol(df) > 0)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
