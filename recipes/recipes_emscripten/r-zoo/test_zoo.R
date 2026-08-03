library(zoo)

print(MATCH(1:5, 2:3))
print(ORDER(rnorm(5)))

## averaging over values in a month:
# x.date is jan 1,3,5,7; feb 9,11,13; mar 15,17,19
x.date <- as.Date(paste(2004, rep(1:4, 4:1), seq(1,20,2), sep = "-")); x.date
x <- zoo(rnorm(12), x.date); x
# coarser dates - jan 1 (4 times), feb 1 (3 times), mar 1 (3 times)
x.date2 <- as.Date(paste(2004, rep(1:4, 4:1), 1, sep = "-")); x.date2
x2 <- aggregate(x, x.date2, mean); x2
# same - uses as.yearmon
x2a <- aggregate(x, as.Date(as.yearmon(time(x))), mean); x2a
# same - uses by function
x2b <- aggregate(x, function(tt) as.Date(as.yearmon(tt)), mean); x2b
# same - uses cut
x2c <- aggregate(x, as.Date(cut(time(x), "month")), mean); x2c
# almost same but times of x2d have yearmon class rather than Date class
x2d <- aggregate(x, as.yearmon, mean); x2d


## aggregate a daily time series to a quarterly series
# create zoo series
tt <- as.Date("2000-1-1") + 0:300
z.day <- zoo(0:300, tt)

# function which returns corresponding first "Date" of quarter
first.of.quarter <- function(tt) as.Date(as.yearqtr(tt))

# average z over quarters
# 1. via "yearqtr" index (regular)
# 2. via "Date" index (not regular)
z.qtr1 <- aggregate(z.day, as.yearqtr, mean)
z.qtr2 <- aggregate(z.day, first.of.quarter, mean)

# The last one used the first day of the quarter but suppose
# we want the first day of the quarter that exists in the series
# (and the series does not necessarily start on the first day
# of the quarter).
z.day[!duplicated(as.yearqtr(time(z.day)))]

# This is the same except it uses the last day of the quarter.
# It requires R 2.6.0 which introduced the fromLast= argument.
## Not run: 
z.day[!duplicated(as.yearqtr(time(z.day)), fromLast = TRUE)]

## End(Not run)

# The aggregated series above are of class "zoo" (because z.day
# was "zoo"). To create a regular series of class "zooreg",
# the frequency can be automatically chosen
zr.qtr1 <- aggregate(z.day, as.yearqtr, mean, regular = TRUE)
# or specified explicitely
zr.qtr2 <- aggregate(z.day, as.yearqtr, mean, frequency = 4)


## aggregate on month and extend to monthly time series
if(require(chron)) {
y <- zoo(matrix(11:15, nrow = 5, ncol = 2), chron(c(15, 20, 80, 100, 110)))
colnames(y) <- c("A", "B")

# aggregate by month using first of month as times for coarser series
# using first day of month as repesentative time
y2 <- aggregate(y, as.Date(as.yearmon(time(y))), head, 1)

# fill in missing months by merging with an empty series containing
# a complete set of 1st of the months
yrt2 <- range(time(y2))
y0 <- zoo(,seq(from = yrt2[1], to = yrt2[2], by = "month"))
merge(y2, y0)
}

# given daily series keep only first point in each month at
# day 21 or more
z <- zoo(101:200, as.Date("2000-01-01") + seq(0, length = 100, by = 2))
zz <- z[as.numeric(format(time(z), "%d")) >= 21]
zz[!duplicated(as.yearmon(time(zz)))]

# same except times are of "yearmon" class
aggregate(zz, as.yearmon, head, 1)

# aggregate POSIXct seconds data every 10 minutes
Sys.setenv(TZ = "GMT")
tt <- seq(10, 2000, 10)
x <- zoo(tt, structure(tt, class = c("POSIXt", "POSIXct")))
aggregate(x, time(x) - as.numeric(time(x)) %% 600, mean)

# aggregate weekly series to a series with frequency of 52 per year
suppressWarnings(RNGversion("3.5.0"))
set.seed(1)
z <- zooreg(1:100 + rnorm(100), start = as.Date("2001-01-01"), deltat = 7)

# new.freq() converts dates to a grid of freq points per year
# yd is sequence of dates of firsts of years
# yy is years of the same sequence
# last line interpolates so dates, d, are transformed to year + frac of year
# so first week of 2001 is 2001.0, second week is 2001 + 1/52, third week
# is 2001 + 2/52, etc.
new.freq <- function(d, freq = 52) {
       y <- as.Date(cut(range(d), "years")) + c(0, 367)
       yd <- seq(y[1], y[2], "year")
       yy <- as.numeric(format(yd, "%Y"))
       floor(freq * approx(yd, yy, xout = d)$y) / freq
}

# take last point in each period
aggregate(z, new.freq, tail, 1)

# or, take mean of all points in each
aggregate(z, new.freq, mean)

# example of taking means in the presence of NAs
z.na <- zooreg(c(1:364, NA), start = as.Date("2001-01-01"))
aggregate(z.na, as.yearqtr, mean, na.rm = TRUE)

# Find the sd of all days that lie in any Jan, all days that lie in
# any Feb, ..., all days that lie in any Dec (i.e. output is vector with
# 12 components)
aggregate(z, format(time(z), "%m"), sd)
