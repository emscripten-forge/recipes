print('Loading usethis package')
library(usethis)
print('... usethis package loaded successfully')

test_1 <- function() {
    stopifnot(is.function(create_package))
    stopifnot(is.function(use_r))
    stopifnot(is.function(proj_get))
}

test_2 <- function() {
    tmp <- tempfile("usethis-pkg-")
    dir.create(tmp)
    old <- setwd(tmp)
    on.exit(setwd(old), add = TRUE)
    create_package("foo", open = FALSE)
    stopifnot(file.exists(file.path("foo", "DESCRIPTION")))
    print(readLines(file.path("foo", "DESCRIPTION"), n = 5))
}

print("Running test_1")
test_1()

print("Running test_2")
test_2()
