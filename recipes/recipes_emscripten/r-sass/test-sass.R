library(sass)

x <- sass(input = "
  $size: 50%;
  foo { margin: $size * .33; }
")
print(x)
