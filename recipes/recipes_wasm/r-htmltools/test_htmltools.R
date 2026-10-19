library(htmltools)

el <- div(HTML("I like <u>turtles</u>"))
cat(as.character(el))

dep <- htmlDependency("deep", "1.0", c(href = "/"))
x <- attachDependencies(div(), dep)
for (i in seq_len(2000L)) x <- div(x)

stopifnot(identical(findDependencies(x, tagify = FALSE), list(dep)))