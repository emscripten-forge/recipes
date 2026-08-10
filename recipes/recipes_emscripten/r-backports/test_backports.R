library(backports)

# Backports for R versions prior to 3.2.0
base::anyNA(1:10)
base::dir.exists(".")

# Backports for R versions prior to 3.3.0
base::startsWith("foobar", "foo")
base::endsWith("foobar", "bar")

# Backports for R versions prior to 3.4.0
utils::hasName("foobar", "foo")

# Backports for R versions prior to 3.5.0
base::isFALSE(FALSE)

# Backports for R versions prior to 3.6.0
base::str2lang("mean(1:10)")
base::str2expression("mean(1:10)")

# Backports for R versions prior to 4.0.0
base::deparse1(quote(mean(5:15)))
base::list2DF(list(a = 1:3, b = 4:6))

# Backports for R versions prior to 4.1.0
base::.libPaths()

# Backports for R versions prior to 4.3.0
tools:::print.Rconcordance(list(x = 1:10))
