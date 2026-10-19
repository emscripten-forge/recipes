library(maps)
library(mapproj)

m <- map("usa", plot=FALSE)
map("usa", project="albers", par=c(39, 45))
map.grid(m)

# get unprojected world limits
m <- map('world', plot=FALSE)

# center on NYC
map('world', proj='azequalarea', orient=c(41, -74, 0))
map.grid(m, col=2)
points(mapproject(list(y=41, x=-74)), col=3, pch="x", cex=2)

map('world', proj='orth', orient=c(41, -74, 0))
map.grid(m, col=2, nx=6, ny=5, label=FALSE, lty=2)
points(mapproject(list(y=41, x=-74)), col=3, pch="x", cex=2)

# center on Auckland
map('world', proj='orth', orient=c(-36.92, 174.6, 0))
map.grid(m, col=2, label=FALSE, lty=2)
points(mapproject(list(y=-36.92, x=174.6)), col=3, pch="x", cex=2)

m <- map('nz')
# center on Auckland
map('nz', proj='azequalarea', orient=c(-36.92, 174.6, 0))
points(mapproject(list(y=-36.92, x=174.6)), col=3, pch="x", cex=2)
map.grid(m, col=2)
