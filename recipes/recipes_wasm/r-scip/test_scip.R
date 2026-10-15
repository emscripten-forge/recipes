print('Loading scip package')
library(scip)
print('... scip package loaded successfully')

test_1 <- function() {
    exports <- getNamespaceExports("scip")
    stopifnot(length(exports) > 0)
    print(head(sort(exports), 10))
}

print("Running test_1")
test_1()
