library(cachem)

stopifnot(is.function(cache_mem))
c <- cache_mem()
c$set("a", 1)
stopifnot(identical(c$get("a"), 1))
