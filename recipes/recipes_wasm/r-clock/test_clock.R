print('Loading clock package')
library(clock)
print('... clock package loaded successfully')

test_1 <- function() {
    library(clock)
    x <- as_year_month_day(year_month_day(2020, 1, 1:5))
    stopifnot(length(x) == 5)
    print(x)
}

test_2 <- function() {
    library(clock)
    x <- as_sys_time(duration_seconds(0:3))
    stopifnot(length(x) == 4)
    print(x)
}

test_3 <- function() {
    library(clock)
    d <- duration_days(1:3)
    stopifnot(as.numeric(d) == 1:3)
    print(d)
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()

print("Running test_3")
test_3()
