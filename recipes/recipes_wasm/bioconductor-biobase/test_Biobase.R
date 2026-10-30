library(Biobase)

test_1 <- function() {
    stopifnot(is.function(ExpressionSet) || exists("ExpressionSet"))
    print(head(sort(getNamespaceExports("Biobase")), 10))
}

test_2 <- function() {
    data(sample.ExpressionSet)
    print(sample.ExpressionSet)
    stopifnot(inherits(sample.ExpressionSet, "ExpressionSet"))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
