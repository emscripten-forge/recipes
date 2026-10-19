library(plyr)

stopifnot(is.function(ddply))
stopifnot(is.function(llply))

df <- data.frame(x = 1:4, g = c("a", "a", "b", "b"))
out <- ddply(df, "g", summarise, mean_x = mean(x))
stopifnot(nrow(out) == 2L)
