library(forecast)

f_ets <- forecast(ets(USAccDeaths))
print(f_ets)
stopifnot(inherits(f_ets, "forecast"), length(f_ets$mean) > 0L)

f_arima <- forecast(auto.arima(WWWusage), h = 20)
print(f_arima)
stopifnot(inherits(f_arima, "forecast"), length(f_arima$mean) == 20L)

library(fracdiff)
x <- fracdiff.sim(100, ma = -0.4, d = 0.3)$series
f_arfima <- forecast(arfima(x), h = 30)
print(f_arfima)
stopifnot(inherits(f_arfima, "forecast"), length(f_arfima$mean) == 30L)

f_stlm <- forecast(stlm(USAccDeaths, modelfunction = ar), h = 36)
print(f_stlm)
stopifnot(inherits(f_stlm, "forecast"), length(f_stlm$mean) == 36L)

f_stlf <- stlf(AirPassengers, lambda = 0)
print(f_stlf)
stopifnot(inherits(f_stlf, "forecast"), length(f_stlf$mean) > 0L)

f_stl <- forecast(stl(USAccDeaths, s.window = "periodic"))
print(f_stl)
stopifnot(inherits(f_stl, "forecast"), length(f_stl$mean) > 0L)

f_tbats <- forecast(tbats(USAccDeaths))
print(f_tbats)
stopifnot(inherits(f_tbats, "forecast"), length(f_tbats$mean) > 0L)
