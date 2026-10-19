library(fansi)

x <- sgr_to_html("\033[31mred\033[39m")
stopifnot(is.character(x), length(x) == 1L)
print(x)
