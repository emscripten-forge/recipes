print('Loading stringi package')
library(writexl)
print('... writexl package loaded successfully.')

test_1 <- function() {
  tmp <- write_xlsx(list(mysheet = iris))
}

test_2 <- function() {
  # Value-only cell
  xl_cell_general(value = 42)

  # Formula with a pre-calculated numeric result (static export)
  xl_cell_general(value = 42.0, formula = "=SUM(A1:A10)")

  # Hyperlink with display text (value) and tooltip
  xl_cell_general(
    value    = "Visit",
    hyperlink = list(url = "https://example.com", tooltip = "Go to example.com")
  )

  # Vector of cells: value and formula cells in one column
  cells <- c(
    xl_cell_general(value = 1.5),
    xl_cell_general(value = "note"),
    xl_cell_general(formula = "=A1+A2")
  )

  # Used in a data frame (length-1 recycles to fill all rows, as with
  # xl_formula())
  df <- data.frame(x = 1:3)
  df$formula_col <- xl_formula("=A1*2")   # backward-compatible shorthand
  df$cell_col    <- xl_cell_general(value = 99L)  # all rows get 99
}

test_3 <- function() {
  xl_chart("column", xl_chart_series(values = list(cols = "revenue")))
  xl_chart("pie", xl_chart_series(values = "Data!B2:B5"), title = "Share")
}

test_4 <- function() {
  xl_chart_table()
  xl_chart_table(show_keys = TRUE, vertical_border = FALSE)
}

test_5 <-function() {
  sales <- data.frame(quarter = c("Q1", "Q2"), revenue = c(10, 25))
  chart <- xl_chart("column",
                    xl_chart_series(values = list(sheet = "Data",
                                                  cols = "revenue")))
  write_xlsx(list(Data = sales, Overview = xl_chartsheet(chart)),
            tempfile(fileext = ".xlsx"))
}

print('Running test 1')
test_1()
print('Running test 2')
test_2()
print('Running test 3')
test_3()
print('Running test 4')
test_4()
print('Running test 5')
test_5()
