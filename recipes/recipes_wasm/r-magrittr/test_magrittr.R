library(magrittr)

x <- 1:5 %>% sum()
stopifnot(identical(x, 15L))
print(x)
