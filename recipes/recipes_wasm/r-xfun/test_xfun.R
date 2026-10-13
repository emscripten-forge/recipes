library(xfun)

Rscript(c("-e", "1+1"))
Rcmd(c("build", "--help"))

x = c("Hello world 123!", "a  &b*^##c 456")
xfun::alnum_id(x)
xfun::alnum_id(x, "[^[:alpha:]]+")  # only keep alphabetical chars
# when text contains HTML tags
xfun::alnum_id("<h1>Hello <strong>world</strong>!")
