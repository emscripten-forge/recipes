library(glue)

x <- glue("hello {1 + 1}")
stopifnot(identical(as.character(x), "hello 2"))
print(x)
