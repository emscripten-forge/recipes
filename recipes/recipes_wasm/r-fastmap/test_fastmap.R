library(fastmap)

m <- fastmap()
m$set("a", 1L)
stopifnot(identical(m$get("a"), 1L))
print(m$as_list())
