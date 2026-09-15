library(rlang)

# CI tests for r-rlang package - non-error focused tests

# Test 1: Test that new_function() creates functions equivalent to regular functions
cat("Running test: new_function() creates equivalent function\n")
f1 <- function(x = a + b, y) {
  x + y
}
attr(f1, "srcref") <- NULL

f2 <- rlang::new_function(alist(x = a + b, y =), quote({x + y}))

stopifnot(identical(f1, f2))
cat("✓ new_function() output matches regular function\n")

# Test 2: Test that as_closure() converts primitive functions to closures
cat("\nRunning test: as_closure() converts primitive functions\n")
closure <- rlang::as_closure(base::list)
stopifnot(identical(typeof(closure), "closure"))
stopifnot(identical(closure(1, 3, 5), list(1, 3, 5)))
stopifnot(identical(closure(a = 1, b = 2), list(a = 1, b = 2)))
cat("✓ as_closure() correctly converts primitive to closure\n")

# Test 3: Test that dots_n() correctly counts dots arguments
cat("\nRunning test: dots_n() counts dots correctly\n")
fn_count <- function(...) rlang::dots_n(...)

stopifnot(identical(fn_count(), 0L))
stopifnot(identical(fn_count(1), 1L))
stopifnot(identical(fn_count(a = 1, b = 2), 2L))
stopifnot(identical(fn_count(1, 2, 3, 4, 5), 5L))
cat("✓ dots_n() correctly counts arguments\n")
