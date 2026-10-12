library(zip)

stopifnot(is.function(deflate))
stopifnot(is.function(inflate))
stopifnot(is.function(unzip))
stopifnot(is.function(unzip_process))
stopifnot(is.function(zip))
stopifnot(is.function(zip_list))
stopifnot(is.function(zip_process))

# Example from documentation
data_gz <- deflate(charToRaw("Hello world!"))
inflate(data_gz$output)
