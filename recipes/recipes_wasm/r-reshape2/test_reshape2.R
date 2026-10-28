print('Loading reshape2 package')
library(reshape2)
print('... reshape2 package loaded successfully')

test_1 <- function() {
    library(reshape2)
    x <- melt(mtcars, id.vars = "cyl", measure.vars = c("mpg", "hp"))
    stopifnot(nrow(x) == 2 * nrow(mtcars))
    print(head(x))
}

test_2 <- function() {
    library(reshape2)
    x <- melt(mtcars, id.vars = "cyl", measure.vars = c("mpg", "hp"))
    y <- dcast(x, cyl ~ variable, mean)
    stopifnot(all(c("mpg", "hp") %in% names(y)))
    print(y)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
