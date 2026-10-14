print('Loading lmtest package')
library(lmtest)
print('... lmtest package loaded successfully')

test_1 <- function() {
    ## Which came first: the chicken or the egg?
    data(ChickEgg)
    ## chickens granger-cause eggs?
    print(grangertest(egg ~ chicken, order = 3, data = ChickEgg))
    ## eggs granger-cause chickens?
    print(grangertest(chicken ~ egg, order = 3, data = ChickEgg))
}

print("Running test_1")
test_1()
