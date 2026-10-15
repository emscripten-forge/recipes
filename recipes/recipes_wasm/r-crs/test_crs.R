library(crs)

test_1 <- function() {
    stopifnot(is.function(crs) || exists("crs", mode = "function") ||
              length(getNamespaceExports("crs")) > 0)
    print(head(sort(getNamespaceExports("crs")), 10))
}

print("Running test_1")
test_1()
