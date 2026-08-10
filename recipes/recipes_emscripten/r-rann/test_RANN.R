print('Loading RANN package')
library(RANN)
print('... RANN package loaded successfully')

test_1 <- function() {

    x1 <- runif(100, 0, 2*pi)
    x2 <- runif(100, 0,3)
    DATA <- data.frame(x1, x2)
    nearest <- nn2(DATA,DATA)
}

print("Running test_1")
test_1()

