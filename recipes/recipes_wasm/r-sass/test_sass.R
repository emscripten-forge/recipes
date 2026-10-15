print('Loading sass package')
library(sass)
print('... sass package loaded successfully')

test_1 <- function() {
    x <- sass(input = "
      $size: 50%;
      foo { margin: $size * .33; }
    ")
    print(x)
    stopifnot(is.character(x) || inherits(x, "css"))
    stopifnot(grepl("margin", paste(x, collapse = "\n")))
}

print("Running test_1")
test_1()
