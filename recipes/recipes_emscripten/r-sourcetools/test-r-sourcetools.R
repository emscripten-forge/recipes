library(sourcetools)

cat("Hello, sourcetools!", file = "output.txt", sep = "\n")
list.files("./")
path <- "./output.txt"

x <- read(path)
print(x)

x <- read_lines(path)
print(x)

x <- read_bytes(path)
print(x)

x <- read_lines_bytes(path)
print(x)

y <- tokenize_file(path)
print(y)

z <- tokenize_string("hello")
print(z)

tokenize(file = "output.txt", text = NULL)
