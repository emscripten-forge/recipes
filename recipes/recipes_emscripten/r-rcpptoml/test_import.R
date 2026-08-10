library(RcppTOML)

toml_file <- tempfile(fileext = ".toml")
writeLines("x = 1", toml_file)

cfg <- parseTOML(toml_file)
print(cfg$x)
