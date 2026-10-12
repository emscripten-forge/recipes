library(data.table)

dt <- data.table(a = 1:3, b = letters[1:3])
stopifnot(nrow(dt) == 3L)
stopifnot(identical(dt$a, 1:3))
print(dt)
