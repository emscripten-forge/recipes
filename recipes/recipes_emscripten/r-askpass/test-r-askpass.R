library(askpass)

stopifnot(is.function(askpassion))
stopifnot(is.function(ssh_askpass))

# Non-interactive, must not prompt, returns NULL per package docs
pw <- askpass("CI test password:")
stopifnot(is.null(pw))

pkgdir <- system.file(package = "askpass")
stopifnot(nzchar(pkgdir))
