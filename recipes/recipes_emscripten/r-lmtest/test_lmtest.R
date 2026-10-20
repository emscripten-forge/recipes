library(lmtest)

## Which came first: the chicken or the egg?
data(ChickEgg)
## chickens granger-cause eggs?
grangertest(egg ~ chicken, order = 3, data = ChickEgg)
## eggs granger-cause chickens?
grangertest(chicken ~ egg, order = 3, data = ChickEgg)
