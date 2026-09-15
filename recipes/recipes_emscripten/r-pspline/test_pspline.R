print('Loading pspline package')
library(pspline)
print('... pspline package loaded successfully')

test_1 <- function() {
    example(smooth.Pspline)
    ## smoother line is given by
    xx <- seq(4, 25, length=100)
    lines(xx, predict(sm.spline(speed, dist, df=5), xx), col = "red")
    ## add plots of derivatives
    lines(xx, 10*predict(sm.spline(speed, dist), xx, 1), col = "blue")
    lines(xx, 100*predict(sm.spline(speed, dist), xx, 2), col = "green")
}

test_2 <- function() {
    data(cars)
    attach(cars)
    plot(speed, dist, main = "data(cars)  &  smoothing splines")
    cars.spl <- sm.spline(speed, dist)
    cars.spl
    lines(cars.spl, col = "blue")
    lines(sm.spline(speed, dist, df=10), lty=2, col = "red")
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

