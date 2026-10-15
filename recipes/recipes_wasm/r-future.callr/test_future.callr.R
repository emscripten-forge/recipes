print('Loading future.callr package')
library(future.callr)
print('... future.callr package loaded successfully')


test_1 <- function() {

    library(future)
    plan(future.callr::callr)
    demo("mandelbrot", package = "future", ask = FALSE)
}

print("Running test_1")
test_1()

