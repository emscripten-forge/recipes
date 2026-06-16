library('png')

png_file <- tempfile(fileext = ".png")
png(png_file)
plot(1:10, 1:10)
dev.off()   